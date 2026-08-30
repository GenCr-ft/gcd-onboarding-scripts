---
docId: GOV-PLAN-272-PROGRESS
title: WI-272 progress — gate interpreter
issue-id: GenCr-ft/gcd-onboarding-scripts#272
status: complete
---

# [CODE] WI-272 progress — evidence ledger

Evidence for GenCr-ft/gcd-onboarding-scripts#272, in the order it was produced.

Record commands **verbatim with their observed output**. A summary of a test run is not
evidence of it, and a green run alone is not evidence that the assertion could have failed.
Never pipe a verifier to `head` or `tail` — that reports the pager's exit status.

## Root-cause verification (pre-implementation)

Branch cut from `origin/main` at `075c3ae` (WI-268 Stage A, `WRAPPER_VERSION=2`).

### The two interpreters, and their order

```
$ which -a python3
/home/lgan/.gft-studio/.poetry/bin/python3
/usr/bin/python3
/bin/python3
/home/lgan/hxgn/dev/claude/exp/gcd-ops-scripts/.venv/bin/python3

$ /usr/bin/python3 -c "import yaml,sys; print(sys.version.split()[0], 'yaml', yaml.__version__)"
3.12.3 yaml 6.0.3

$ /home/lgan/.gft-studio/.poetry/bin/python3 -c "import yaml"
ModuleNotFoundError: No module named 'yaml'
```

The yaml-less interpreter is **first**. The gate is broken in this session's environment
as it stands, with no manipulation.

Incidental, and confirming the report: `/home/lgan/.local/bin` appears **four** times in
`PATH` (the report said three).

### Same linter, same tree, two PATH orderings

```
$ "$L" ; echo "exit=$?"                  # $L = .../linters/validate_planning_metadata.py
  File ".../validate_planning_metadata.py", line 10, in <module>
    import yaml
ModuleNotFoundError: No module named 'yaml'
exit=1

$ PATH=/usr/bin:$PATH "$L" ; echo "exit=$?"
✗ SSoT Planning Metadata Linter errors found:
  - No planning folder found under '.planning/' matching active branch issue ID '272'.
exit=1
```

### The exit code carries no information

```
crash exit   = 1        (ModuleNotFoundError)
verdict exit = 1        (sys.exit(1), validate_planning_metadata.py:265)
```

Indistinguishable. Keying the fix on an exit signature — as the report proposes — is
unimplementable. The distinction must be established before invocation.

### The pin already exists and is bypassed

```
$ grep -A1 'tool.poetry.scripts' gcd-ops-scripts/pyproject.toml
validate-planning-metadata = "gft_ops_scripts.linters.validate_planning_metadata:main"

$ grep PyYAML gcd-ops-scripts/pyproject.toml
PyYAML = ">=6.0.2"

$ head -1 gcd-ops-scripts/.venv/bin/validate-planning-metadata
#!/home/lgan/hxgn/dev/claude/exp/gcd-ops-scripts/.venv/bin/python

$ env PATH=/nonexistent .venv/bin/validate-planning-metadata ; echo "exit=$?"
Running SSoT Planning Metadata validation...
✓ Planning metadata is fully compliant.
exit=0
```

The interpreter resolved with `PATH` emptied — `PATH`-independent by construction. (That
run is green only because emptying `PATH` also removed `git`; see below.)

### Out-of-scope discovery: the same gate fails OPEN on git

`validate_planning_metadata.py:18-30` resolves the active branch under a blanket
`except Exception` returning the literal `"main"`, which carries no issue ID, so the
traceability assertion is skipped entirely. Isolated to `git` alone — identical script,
cwd and tree, `python3`/`sh`/`bash`/`ls` symlinked into a scratch `PATH`, `git` omitted:

```
### control: git present
$ env PATH="/usr/bin:/bin" .venv/bin/validate-planning-metadata ; echo "exit=$?"
✗ SSoT Planning Metadata Linter errors found:
  - No planning folder found under '.planning/' matching active branch issue ID '272'.
exit=1

### variant: identical, git REMOVED from PATH only
$ env PATH="$D/bin" .venv/bin/validate-planning-metadata ; echo "exit=$?"
✓ Planning metadata is fully compliant.
exit=0
```

A real violation reported as full compliance. Filed as GenCr-ft/gcd-ops-scripts#189 and
boarded on Project #16. Not fixed here — it is in the linter, not the generator.

## DESIGN approval

`[DESIGN]` #276 approved by `loigallain` on all three decisions and closed;
`status:approved` applied to #276 and #277. Verified against the predicate rather than by
reading labels, because the label is what the gate resolves:

```
$ python3 -c "import issue_context_gate as g; print(g._check_implement_phase('GenCr-ft/gcd-onboarding-scripts', 272))"
(0, '')          # previously (2, '... requires status:approved label set by a human reviewer')
```

Before the label existed, the gate's PreToolUse path nonetheless **permitted** two real
`Edit` calls while that predicate returned a block. Both were reverted and no
implementation was started until the label was applied. Filed as
GenCr-ft/gcs-plt-gemop#536.

## Red — `b212a41`

`bash tests/test_precommit_wrapper.sh`, verbatim:

```
=== AC-272.1 (MUST-FIRE): an unrunnable linter reads as 'cannot run', not 'failed' ===
  FAIL  an unrunnable gate does not report a validation failure
          names neither the requirement nor an interpreter:
=== AC-272.2 (MUST-FIRE): it still refuses the commit, distinguishably ===
  FAIL  an unrunnable gate refuses the commit with a code distinct from a verdict
          exit 0 — a broken gate was turned into a passing one
=== AC-272.3 (MUST-FIRE): the linter executed is identical under two PATH orderings ===
  FAIL  the linter executed, and the verdict, are PATH-independent
          run1=[RAN=A rc=0] run2=[RAN=B rc=0]
=== AC-272.4 (MUST-FIRE): a yaml-less python3 leading PATH no longer blocks a clean commit ===
  FAIL  a compliant commit survives a yaml-less interpreter at the head of PATH
          rc=1 out=ModuleNotFoundError: No module named 'yaml'|[TRACEABILITY GATE] Planning metadata validation failed. Commit aborted.
=== AC-272.5 (MUST-NOT-FIRE): a genuine violation still reports as a validation failure ===
  ok    a genuine violation still reports as a validation failure, exit 1
=== AC-272.6 (MUST-NOT-FIRE): the deployer still exits 0 on success ===
  ok    deploy_planning_metadata_hook exits 0 on success

  passed=10 failed=4
```

`AC-272.4` is the reported defect end to end. `AC-272.3` shows two different linters
running for the same commit — `RAN=A` and `RAN=B` — which is the governance property, not a
message property. The two MUST-NOT-FIRE arms pass here and must still pass after, so they
are not vacuous.

## Green

Two of my own defects were caught by the arms before the suite went green, and both are
worth recording because each would have shipped a wrong fix that looked right.

**1. `command -v validate-planning-metadata` broke hermeticity and correctness.** The
first revision accepted a `command -v` hit as the entry point. Three arms then failed with
the *real* linter's output against a mock workspace:

```
  FAIL  an unrunnable gate does not report a validation failure
          names neither the requirement nor an interpreter: Running SSoT Planning Metadata validation...||✓ Planning metadata is fully compliant.
  FAIL  a genuine violation still reports as a validation failure, exit 1
          rc=0 out=Running SSoT Planning Metadata validation...||✓ Planning metadata is fully compliant.
```

`/home/lgan/hxgn/dev/claude/exp/gcd-ops-scripts/.venv/bin` is on this machine's `PATH`, so
the fixture's generated wrapper resolved the developer's real entry point. That is the same
ambient resolution this WI removes, re-introduced through a different variable — and worse,
it let source and execution disagree, since `linter_src` is resolved from `target_dir`
while a global hit could be a different revision of the linter entirely. Fixed by
resolving the entry point from `target_dir` only.

**2. The requirement override was read at source time, not generation time.** With
`command -v` removed, AC-272.1/.2 still failed with empty output and exit 0: the include is
sourced once at startup, so `GFT_LINTER_REQUIRED_MODULE` exported around the
`deploy_planning_metadata_hook` call arrived too late. Resolved inside the function
instead.

After both fixes:

```
  ok    an unrunnable gate does not report a validation failure
  ok    an unrunnable gate refuses the commit with a code distinct from a verdict
  ok    the linter executed, and the verdict, are PATH-independent
  ok    a compliant commit survives a yaml-less interpreter at the head of PATH
  ok    a genuine violation still reports as a validation failure, exit 1
  ok    deploy_planning_metadata_hook exits 0 on success

  passed=14 failed=0
```

All 14 arms in the file, including the 8 pre-existing WI-268 arms, pass.

### AC-272.7 — a residual instance of the same defect, in the path now made primary

Found by reviewing the finished generated block rather than by a failing test. The entry
point is now the **primary** path, so a venv whose interpreter has been moved or deleted is
the likeliest residual failure — and bash reports that as `126`/`127`, which the first
implementation passed straight through to be relabelled `Planning metadata validation
failed`. The original defect, one layer in.

Fixed by mapping `126`/`127` from the entry point to CANNOT-RUN, and extracting the message
into `gate_cannot_run()` so both callers say the same thing. Proven capable of failing, by
stashing only the generator and keeping the arm:

```
$ git stash push -- includes/06_workspace_files.sh
$ bash tests/test_precommit_wrapper.sh
=== AC-272.7 (MUST-FIRE): a broken entry point is 'cannot run', not a verdict ===
  FAIL  a broken entry point reads as 'cannot run'
          said 'validation failed' — an exec failure is dressed as a verdict
  passed=14 failed=1
```

With the fix restored: `passed=15 failed=0`.

## Verification

### Whole suite — 19 files

```
$ bash test.sh
FULL SUITE exit=1
  workspace_files: Passed: 52  Failed: 0
  ✓ tests/test_workspace_files.sh passed
  ✗ tests/test_studio_home_e2e.sh failed
✗ One or more tests failed.
```

`tests/test_workspace_files.sh` passes **52/0**, including its
`deploy_planning_metadata_hook exits 0 on success` contract at line 141 — nothing new was
folded into that return code.

The single failure, `tests/test_studio_home_e2e.sh`, is **pre-existing and unrelated** — and
my first characterisation of it was wrong. It failed three consecutive times, including on
clean `origin/main`, so I filed it as "red on main". After the suite had run once it passes,
and `6/6` on repeat:

```
$ bash test.sh
exit=0
$ for i in 1 2 3 4 5 6; do bash tests/test_studio_home_e2e.sh >/dev/null 2>&1; echo "run$i exit=$?"; done
run1..run6 exit=0
```

So it is **flaky / order-dependent**, not deterministic. Mechanism found:
`gft-onboarding.sh:62` declares `readonly GFT_SSOT_PATH="/tmp/gft-ssot-onboarding"` — a
hardcoded shared path outside any hermetic `HOME`, and unoverridable — while the test's own
`seed_mock_ssot` begins `rm -rf "$GFT_SSOT_PATH"`. Tests interfere through a fixed global
path, so the suite is also unsafe to run concurrently with itself. Correction and revised
controls posted to #278. The unconditional finding stands: whenever it fails it fails
**silently**, because the captured output is discarded and inherited `set -e` pre-empts the
test's own reporting.

The original evidence, real when measured:

```
$ git worktree add /tmp/wi272-baseline origin/main --detach
HEAD is now at 075c3ae fix(hooks): WI-268 Stage A — ...
$ bash tests/test_studio_home_e2e.sh; echo "exit=$?"
exit=1                      # zero lines of output
```

It fails identically with zero output on `main`. Investigated far enough to file it
truthfully: the test captures the real onboarding run's stdout+stderr into a `mktemp` file
and never prints it, and it inherits `set -e` from the sourced `gft-onboarding.sh`, so the
failing call aborts before any `[FAIL]` line or summary can print. With the subshell's
failure made non-fatal, **all three scenario assertions pass** — so the failure is in
`onboarding_main`'s exit status, not in the behaviour the test pins. Filed as
GenCr-ft/gcd-onboarding-scripts#278.

### Lint

```
$ shellcheck --severity=error includes/06_workspace_files.sh tests/test_precommit_wrapper.sh
exit=0
```

At default severity the changed files report `SC2030`/`SC2031` (PATH modified in a
subshell) six and three times. Those are in the new arms and are **deliberate**: each arm
scopes its `PATH` to a subshell precisely so the arms cannot leak into one another. CI
enforces `--severity=error`, and the tree's norm already carries info-level codes
(`SC1091` on `origin/main`). Not suppressed with a directive, because the pattern is
correct and a disable comment would only hide a true observation.

`yamllint .` reports only pre-existing findings in `.github/workflows/` — untouched by this
change, and against the 80-column default rather than the studio's 120. No YAML file is
modified: `git diff --name-only origin/main` lists two `.planning/` files,
`includes/06_workspace_files.sh`, `tests/test_precommit_wrapper.sh` and `CHANGELOG.md`.

### The gate ran on every commit

No `--no-verify`. Each commit went through a script file with `/usr/bin` prefixed on
`PATH`, and the gate's own banner is the proof it executed rather than being skipped:

```
### commit (the gate runs here)
Running SSoT Planning Metadata validation...

✓ Planning metadata is fully compliant.
```
