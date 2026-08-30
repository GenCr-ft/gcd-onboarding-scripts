---
docId: GOV-PLAN-272
title: WI-272 — gate interpreter
issue-id: GenCr-ft/gcd-onboarding-scripts#272
status: in_progress
---

# [CODE] WI-272 — gate interpreter

Implementation plan for GenCr-ft/gcd-onboarding-scripts#272.

## Problem

`includes/06_workspace_files.sh` generates the studio pre-commit wrapper into every
workspace clone. Step 1 of that wrapper executes the planning-metadata linter as a bare
executable, so its interpreter is whatever `PATH` resolves at commit time. Two defects
follow:

1. **A crash is printed as a verdict.** When the resolved interpreter lacks the linter's
   `PyYAML` requirement, the wrapper prints `Planning metadata validation failed` — which
   sends the author hunting for a frontmatter error that does not exist.
2. **The interpreter is unpinned.** A governance gate's answer changes with the shell
   environment. Verified on this machine: the yaml-less interpreter is currently *first*
   on `PATH`, and the same commit that passed earlier in the day was hard-blocked later.

Failing closed on a crash is the correct direction and is preserved. Only the diagnosis
and the interpreter resolution change.

## Verified root cause

Measured against `origin/main` at `075c3ae`, not taken from the report:

- `which -a python3` resolves `/home/lgan/.gft-studio/.poetry/bin/python3` (no `yaml`)
  before `/usr/bin/python3` (`yaml 6.0.3`).
- **The exit code carries no information.** A `ModuleNotFoundError` crash and a genuine
  violation (`sys.exit(1)`, `validate_planning_metadata.py:265`) both exit `1`. The
  report's proposal to key on "a specific exit signature" is therefore unimplementable;
  the distinction must be established *before* invocation.
- **The pin already exists and is being bypassed.** `gcd-ops-scripts` declares
  `PyYAML >= 6.0.2` as a runtime dependency and ships a `validate-planning-metadata`
  console script whose shebang is an absolute path into the environment that declares it.
  It runs correctly with `PATH` emptied. The wrapper reaches past it to execute the raw
  source file, re-acquiring the `PATH` dependency packaging had already removed.
- **The gate is also `PATH`-dependent in the fail-open direction**, one layer down: the
  linter resolves the active branch via `subprocess.run(["git", ...])` under a blanket
  `except Exception` that falls back to the string `"main"`, which carries no issue ID,
  so a real violation is reported as `✓ Planning metadata is fully compliant.` with exit
  `0`. Out of scope here (it is in the linter, not the generator) — filed as
  GenCr-ft/gcd-ops-scripts#189, boarded on Project #16.

## Approach

Resolve the **installed entry point** at generation time and bake it into the wrapper,
exactly as the linter's source path is already baked. The pin then comes from packaging
metadata maintained where the dependency is declared, not from a shell mirror of another
repo's `pyproject.toml`.

Ordered resolution, with the fallback probed rather than assumed:

1. an installed `validate-planning-metadata` console script (absolute shebang,
   `PATH`-independent);
2. failing that, a candidate interpreter **verified** to import the requirement, running
   the source file;
3. failing that, a truthful "cannot run" refusal — fail closed, naming what was tried,
   with an exit code distinct from the linter's verdict code. Explicitly **not** a silent
   degradation back to today's bare `python3`.

`WRAPPER_VERSION` bumps `2` → `3`. Without it the skip branch leaves the fleet's v2
wrappers in place, which is precisely the failure mode WI-268 Stage A had to repair.

## Scope

**In:** `includes/06_workspace_files.sh` (`deploy_planning_metadata_hook`, generated step
1 and the generation-time resolution feeding it), `WRAPPER_VERSION` bump, new arms in
`tests/test_precommit_wrapper.sh`, `CHANGELOG.md`.

**Out:** the wrapper's step 2 delegation (WI-268's territory, untouched); the linter's
internals and its `git` fail-open (#189); `.github/workflows/`; the duplicated
`/home/lgan/.local/bin` entries in the onboarding `PATH` assembly (real, cosmetic,
separate).

## Controls

| Arm | Case | Today |
|---|---|---|
| MUST-FIRE | dependency unsatisfiable → message names requirement + interpreters tried, and does not say "validation failed" | fails |
| MUST-FIRE | same case still exits non-zero, code distinct from the verdict code | partly — non-zero, but the code collides |
| MUST-FIRE | interpreter identity stable across two `PATH` orderings | fails |
| MUST-NOT-FIRE | genuine violation still reported as a validation failure | passes, must stay |
| MUST-NOT-FIRE | compliant commit still passes | passes, must stay |
| MUST-NOT-FIRE | `deploy_planning_metadata_hook` still exits 0 on success (`tests/test_workspace_files.sh:141`) | passes, must stay |

Every arm stages its own fixture workspace under a `mktemp -d` `HOME` with `trap`
cleanup, per the convention already documented at the head of
`tests/test_precommit_wrapper.sh`. The generator iterates children of
`GFT_PROJECTS_HOME` containing `.git` and writes into their `.git/hooks`; an arm that
forgets to override it deploys hooks into the developer's real clones.

Arms assert on **behaviour** — the wrapper's output and exit status when executed — never
by grepping the generated file for a string. A text match can fail a correct fix or pass
on a comment.

## Lifecycle

Full tier: this changes enforcement behaviour in a git hook generated into every
workspace clone, and alters a gate's exit-code contract.

| Gate | State |
|---|---|
| REFINE | ✅ analysis posted on #272, `LIFECYCLE:REFINE:PASS` recorded |
| DESIGN | sub-issue raised — **stops for human approval** |
| PLAN | this file |
| IMPLEMENT | blocked on DESIGN approval |

## Notes

Commits in this repo run the very wrapper under repair. `git commit --no-verify` is not
used: bypassing the gate to land a change that repairs the gate would be self-refuting.
Commits are made through a script file that puts a working interpreter first on `PATH`,
so the gate genuinely runs and genuinely passes.
