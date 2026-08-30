---
docId: GOV-PLAN-272-PROGRESS
title: WI-272 progress — gate interpreter
issue-id: GenCr-ft/gcd-onboarding-scripts#272
status: in_progress
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

## Red

_Pending DESIGN approval._

## Green

_Pending DESIGN approval._

## Verification

_Pending. Must include a full `bash test.sh` run (the whole suite, not only the new arms —
`tests/test_workspace_files.sh:141` asserts a pre-existing contract this change could
break), written to a log and grepped rather than piped to a pager._
