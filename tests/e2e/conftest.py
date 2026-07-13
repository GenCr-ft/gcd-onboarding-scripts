"""pytest configuration for the F1.5 end-to-end boot-chain proof.

Registers the ``e2e`` marker and exposes prerequisite-detection helpers so the
boot-chain proof SKIPS (never falsely fails) on a host that lacks docker or a
uWebSockets.js-compatible Node runtime. The green run is produced by the
boot-chain-smoke CI job (Diane, gcs-project-management#414 §3).
"""

from __future__ import annotations

import glob
import os
import shutil
import subprocess
from pathlib import Path


# ── Workspace layout ─────────────────────────────────────────────────────────
# tests/e2e/conftest.py → repo root is two levels up; the multi-repo workspace
# (where sibling repos are cloned) is the launcher's WORKSPACE, overridable via
# the AETHEL_WORKSPACE env var for CI checkouts that use a different layout.
REPO_ROOT = Path(__file__).resolve().parents[2]
WORKSPACE = Path(os.environ.get("AETHEL_WORKSPACE", REPO_ROOT.parent))
LAUNCHER = REPO_ROOT / "workspace" / "run-walking-skeleton.sh"

# Ports the launcher binds (kept in sync with run-walking-skeleton.sh).
AUTH_PORT = 3010
GAME_HTTP_PORT = 3100
GAME_WS_PORT = 3001
ALL_PORTS = (AUTH_PORT, GAME_HTTP_PORT, GAME_WS_PORT)


def pytest_configure(config) -> None:
    config.addinivalue_line(
        "markers",
        "e2e: end-to-end boot-chain proof — requires docker + a uWS-compatible "
        "Node runtime; skipped automatically when they are absent.",
    )


def docker_available() -> bool:
    """True when the docker CLI is present and the daemon answers."""
    if shutil.which("docker") is None:
        return False
    try:
        return (
            subprocess.run(
                ["docker", "info"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=15,
            ).returncode
            == 0
        )
    except (OSError, subprocess.SubprocessError):
        return False


def _node_abi(node_bin: str) -> str | None:
    try:
        return subprocess.run(
            [node_bin, "-e", "process.stdout.write(process.versions.modules)"],
            capture_output=True,
            text=True,
            timeout=15,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None


def uws_node_available() -> bool:
    """Mirror the launcher's find_uws_node: some candidate Node's ABI must match
    a prebuilt uWebSockets.js binary shipped in the game server's node_modules."""
    uws_dir = WORKSPACE / "gcp-aethel-server" / "node_modules" / "uWebSockets.js"
    shipped = {
        Path(p).stem.rsplit("_", 1)[-1]
        for p in glob.glob(str(uws_dir / "uws_linux_x64_*.node"))
    }
    if not shipped:
        return False
    candidates: list[str] = []
    home = Path.home()
    for major in ("v22.", "v21.", "v20.", "v18."):
        candidates += [str(p) for p in home.glob(f".nvm/versions/node/{major}*/bin/node")]
    for fallback in (shutil.which("node"), "/usr/bin/node", "/usr/local/bin/node"):
        if fallback:
            candidates.append(fallback)
    return any(_node_abi(c) in shipped for c in candidates if Path(c).exists())


def prerequisites_missing() -> str | None:
    """Return a human-readable reason to skip, or None when the box is ready.

    This is an E2E proof of *merged-main* behaviour, so it also verifies the F1.5
    stack is actually deployed on the checkout before attempting a run: the
    launcher must carry the smoke-exit contract (gcd-onboarding-scripts#243) and
    the auth service must ship its dev-session compose file (gcl-srv-auth#110).
    Absent those, the correct outcome is skip ("stack not merged"), not failure.
    """
    if not LAUNCHER.exists():
        return f"launcher not found at {LAUNCHER}"
    for repo in ("gcl-srv-authentication", "gcp-aethel-server", "gcl-voxel-engine"):
        if not (WORKSPACE / repo).is_dir():
            return f"sibling repo {repo} not cloned under {WORKSPACE}"
    if "AETHEL_BOOT_PROOF" not in LAUNCHER.read_text(encoding="utf-8"):
        return "launcher lacks the smoke-exit contract (F1.5 stack not merged)"
    if not (WORKSPACE / "gcl-srv-authentication" / "docker-compose.dev.yml").is_file():
        return "gcl-srv-authentication/docker-compose.dev.yml absent (F1.5 stack not merged)"
    if not docker_available():
        return "docker CLI or daemon unavailable"
    if not uws_node_available():
        return "no Node runtime with a uWS.js-compatible ABI (nvm install 20)"
    return None
