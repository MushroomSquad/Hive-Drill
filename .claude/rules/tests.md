---
description: Test writing standards for the built-in test runner. Applied when reading, writing, or reviewing files in tests/.
globs:
  - "tests/**/*.sh"
  - "tests/*.sh"
---

# Rules: tests/

## Test runner

All tests run through `tests/run_tests.sh`. No external test frameworks — stdlib bash only.

## File naming

- One test file per script: `tests/test_<script_name>.sh`
- Test functions: `test_<function_or_behavior>()`

## Minimum coverage per script

Every public script function must have:
1. **Happy path** — correct input, expected output
2. **Error path** — invalid input or failing precondition
3. At least one **edge case** visible from the script logic

## Test function structure

```bash
test_<name>() {
    # Arrange
    local input="..."

    # Act
    local result
    result=$(./scripts/<name>.sh "$input" 2>&1)
    local exit_code=$?

    # Assert
    if [[ "$result" != "expected" ]]; then
        echo "FAIL: test_<name> — expected 'expected', got '$result'"
        return 1
    fi
    echo "PASS: test_<name>"
}
```

## Isolation

- Tests must not depend on each other's state
- Use `mktemp -d` for temp directories; clean up with a trap
- Do not modify files outside the temp directory during tests
- Do not make network calls

## Generating tests with Codex

When asking Codex to generate tests, pass it:
1. The script under test
2. An existing test file as a style example
3. The list of functions to cover

Use `local-fast` profile — test generation is P2 work.

## What not to do

- Do not assert on timestamps or PIDs
- Do not use `sleep` in tests — use deterministic conditions
- Do not write tests that pass by ignoring exit codes
- Do not hardcode absolute paths — derive them from `$REPO_ROOT` or relative paths
