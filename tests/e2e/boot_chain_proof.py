"""F1.5 — End-to-end boot-chain proof for milestone M1 (First-Boot Demo).

Proves the player-boot vertical slice end to end: the walking-skeleton launcher
brings up docker (Postgres + Redis), the auth service, and the game server; a
headless WebSocket client authenticates and receives the boot handshake; the
game server signals spawn completion; and the whole stack tears down cleanly.

Sequence (Forge contract, gcs-project-management#414; [DESIGN] #507):

  1. Popen the launcher with ``--smoke-exit-after-spawn``.
  2. Read its stdout until ``AETHEL_BOOT_PROOF:SERVICES_READY``.
  3. Register + log in a dev user via the auth REST API → JWT.
  4. Open ws://localhost:3001 with the JWT as the Sec-WebSocket-Protocol
     subprotocol; assert SessionWelcome (0x02) then ChunkData (0x11, 98317 B).
  5. Read launcher stdout until ``AETHEL_SPAWN_COMPLETE``.
  6. SIGTERM the launcher; assert ``AETHEL_BOOT_PROOF:CLEAN_EXIT`` + exit code 0.
  7. Assert no orphan process still holds ports 3001/3010/3100.

The test SKIPS (never falsely fails) when docker or a uWS-compatible Node
runtime is absent; the green run is produced by the boot-chain-smoke CI job
which provisions them (Diane, #414 §3).
"""

from __future__ import annotations

import os
import queue
import signal
import socket
import subprocess
import threading
import time

import pytest
import requests
import websockets.sync.client as ws_client

from conftest import (
    ALL_PORTS,
    AUTH_PORT,
    GAME_WS_PORT,
    LAUNCHER,
    WORKSPACE,
    prerequisites_missing,
)

# ── Wire contract (gcp-aethel-server/src/infrastructure/transport/message-codec.ts)
MSG_SESSION_WELCOME = 0x02
MSG_CHUNK_DATA = 0x11
CHUNK_VOXEL_DATA_SIZE = 98304
CHUNK_FRAME_SIZE = 1 + 12 + CHUNK_VOXEL_DATA_SIZE  # type + cx/cy/cz int32 LE + voxels

# ── Boot-proof sentinels (must match launcher + game server) ─────────────────
SENTINEL_SERVICES_READY = "AETHEL_BOOT_PROOF:SERVICES_READY"
SENTINEL_SPAWN_COMPLETE = "AETHEL_SPAWN_COMPLETE"
SENTINEL_CLEAN_EXIT = "AETHEL_BOOT_PROOF:CLEAN_EXIT"

# ── Timeouts (generous: first run compiles TS + pushes Prisma schema) ────────
SERVICES_READY_TIMEOUT_S = 300
SPAWN_COMPLETE_TIMEOUT_S = 30
CLEAN_EXIT_TIMEOUT_S = 20

DEV_EMAIL = "dev@aethel.local"
DEV_PASSWORD = "Password1!"


pytestmark = pytest.mark.e2e


def _port_is_free(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("127.0.0.1", port))
            return True
        except OSError:
            return False


class _LauncherProcess:
    """Runs the launcher and streams its combined stdout to a line queue so the
    test can wait for a sentinel without blocking on the pipe forever."""

    def __init__(self) -> None:
        env = dict(os.environ, WORKSPACE=str(WORKSPACE))
        self.proc = subprocess.Popen(
            ["bash", str(LAUNCHER), "--smoke-exit-after-spawn"],
            cwd=str(WORKSPACE),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            env=env,
            # New process group so SIGTERM reaches the launcher, not just bash's
            # foreground child, exercising the launcher's own TERM trap.
            start_new_session=True,
        )
        self.lines: "queue.Queue[str | None]" = queue.Queue()
        self.transcript: list[str] = []
        self._reader = threading.Thread(target=self._pump, daemon=True)
        self._reader.start()

    def _pump(self) -> None:
        assert self.proc.stdout is not None
        for line in self.proc.stdout:
            self.transcript.append(line.rstrip("\n"))
            self.lines.put(line)
        self.lines.put(None)  # EOF sentinel

    def wait_for(self, needle: str, timeout_s: float) -> bool:
        """Consume stdout lines until one contains ``needle``. Returns False if
        the stream ends or the deadline passes first."""
        deadline = time.monotonic() + timeout_s
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return False
            try:
                line = self.lines.get(timeout=remaining)
            except queue.Empty:
                return False
            if line is None:  # process exited
                return False
            if needle in line:
                return True

    def dump(self) -> str:
        return "\n".join(self.transcript[-60:])

    def terminate_group(self, sig: int = signal.SIGTERM) -> None:
        try:
            os.killpg(os.getpgid(self.proc.pid), sig)
        except (ProcessLookupError, PermissionError):
            pass

    def hard_kill(self) -> None:
        if self.proc.poll() is None:
            self.terminate_group(signal.SIGKILL)
            try:
                self.proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                pass


def _obtain_jwt() -> str:
    """Register (idempotent) then log in the dev user; return the access token."""
    base = f"http://localhost:{AUTH_PORT}"
    requests.post(
        f"{base}/auth/register",
        json={"email": DEV_EMAIL, "password": DEV_PASSWORD, "displayName": "DevPlayer"},
        timeout=15,
    )  # 201 (created) or 409 (already exists) are both fine
    resp = requests.post(
        f"{base}/auth/login",
        json={"email": DEV_EMAIL, "password": DEV_PASSWORD},
        timeout=15,
    )
    resp.raise_for_status()
    body = resp.json()
    token = body.get("accessToken") or body.get("access_token")
    assert token, f"login response missing access token: {body}"
    return token


def _assert_boot_handshake(token: str) -> None:
    """Connect the WS client and assert SessionWelcome (0x02) then ChunkData."""
    # The server reads the JWT from the Sec-WebSocket-Protocol header
    # (uws-transport.adapter.ts:318). websockets sends `subprotocols` there.
    with ws_client.connect(
        f"ws://localhost:{GAME_WS_PORT}",
        subprotocols=[token],
        open_timeout=15,
        max_size=CHUNK_FRAME_SIZE * 2,
    ) as conn:
        welcome = conn.recv(timeout=15)
        assert isinstance(welcome, (bytes, bytearray)), "SessionWelcome must be binary"
        assert welcome[0] == MSG_SESSION_WELCOME, (
            f"expected SessionWelcome 0x{MSG_SESSION_WELCOME:02x}, "
            f"got 0x{welcome[0]:02x}"
        )

        chunk = conn.recv(timeout=15)
        assert isinstance(chunk, (bytes, bytearray)), "ChunkData must be binary"
        assert chunk[0] == MSG_CHUNK_DATA, (
            f"expected ChunkData 0x{MSG_CHUNK_DATA:02x}, got 0x{chunk[0]:02x}"
        )
        assert len(chunk) == CHUNK_FRAME_SIZE, (
            f"ChunkData frame must be {CHUNK_FRAME_SIZE} bytes "
            f"(1+12+{CHUNK_VOXEL_DATA_SIZE}), got {len(chunk)}"
        )


def test_boot_chain_reaches_spawn_and_exits_clean() -> None:
    reason = prerequisites_missing()
    if reason:
        # In CI the M1 gate MUST actually run: a silent skip would exit 0 and
        # masquerade as a pass. AETHEL_REQUIRE_E2E=1 turns "not ready" into a
        # hard failure so the boot-chain-smoke job can only go green on a real run.
        if os.environ.get("AETHEL_REQUIRE_E2E") == "1":
            pytest.fail(f"E2E required but prerequisites missing: {reason}")
        pytest.skip(f"boot-chain prerequisites missing: {reason}")

    launcher = _LauncherProcess()
    try:
        assert launcher.wait_for(SENTINEL_SERVICES_READY, SERVICES_READY_TIMEOUT_S), (
            "launcher never reported services ready.\n"
            f"--- launcher tail ---\n{launcher.dump()}"
        )

        token = _obtain_jwt()
        _assert_boot_handshake(token)

        assert launcher.wait_for(SENTINEL_SPAWN_COMPLETE, SPAWN_COMPLETE_TIMEOUT_S), (
            "game server never emitted AETHEL_SPAWN_COMPLETE after the initial "
            f"chunk.\n--- launcher tail ---\n{launcher.dump()}"
        )

        # Clean-teardown proof: SIGTERM → launcher TERM trap → CLEAN_EXIT → rc 0.
        launcher.terminate_group(signal.SIGTERM)
        assert launcher.wait_for(SENTINEL_CLEAN_EXIT, CLEAN_EXIT_TIMEOUT_S), (
            "launcher did not report a clean exit on SIGTERM.\n"
            f"--- launcher tail ---\n{launcher.dump()}"
        )
        try:
            rc = launcher.proc.wait(timeout=CLEAN_EXIT_TIMEOUT_S)
        except subprocess.TimeoutExpired:
            pytest.fail("launcher did not exit within the clean-exit window")
        assert rc == 0, f"launcher exited {rc}, expected 0 (clean shutdown)"
    finally:
        launcher.hard_kill()

    # No orphan must still hold a boot-chain port.
    time.sleep(1)
    held = [p for p in ALL_PORTS if not _port_is_free(p)]
    assert not held, f"ports still held after teardown (orphaned processes?): {held}"
