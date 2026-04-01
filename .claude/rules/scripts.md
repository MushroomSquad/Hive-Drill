---
description: Coding standards for all files in scripts/. Applied when reading, writing, or reviewing any script.
globs:
  - "scripts/**/*.sh"
  - "scripts/*.sh"
---

# Rules: scripts/

## Mandatory header

Every script must start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

No exceptions. Scripts without this header will fail `ai-check.sh`.

## Naming

- Constants and environment variables: `UPPER_CASE`
- Local variables: `lower_case`
- Function names: `lower_case_with_underscores`

## Error handling

- Do not add `|| true` to suppress errors unless you explicitly intend to ignore failure and document why
- Use `set -euo pipefail` — it handles most error propagation
- For expected-failure cases, use explicit checks: `if ! command; then ...`

## Function structure

Every public function must:
1. Have a comment if its purpose is not self-evident from the name
2. Have a corresponding test in `tests/test_<script_name>.sh`

## Output

- Status messages: `echo "[hive] ..."` prefix
- Errors: `echo "[hive] ERROR: ..." >&2`
- Do not use `printf` unless formatting requires it

## Dependencies

- No external tools beyond what is listed in `install.sh`
- No `curl | bash` patterns
- No internet calls from scripts — that belongs to agent-level code

## What not to do

- Do not hardcode paths that should be discovered dynamically
- Do not source `.env` in scripts — let the caller set environment
- Do not write to `/tmp` without a cleanup trap
