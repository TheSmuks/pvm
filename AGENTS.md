# Project Context

This file is auto-discovered by AI coding agents. It provides project-level context that guides agent behavior.

## Project Overview

- **Name**: pvm — Pike Version Manager
- **Description**: A POSIX-compliant shell script that manages multiple Pike installations per-user, modeled after nvm
- **Primary Language**: POSIX shell (bash/zsh compatible)
- **License**: MPL / LGPL / GPL (triple-licensed, same as Pike)

## Build & Run

```bash
# There is no build step — pvm is a sourced shell script

# Install (bootstrap)
curl -o- https://raw.githubusercontent.com/TheSmuks/pvm/main/install.sh | bash

# Or manually
git clone https://github.com/TheSmuks/pvm.git ~/.pvm
echo 'export PVM_DIR="$HOME/.pvm"' >> ~/.bashrc
echo '[ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"' >> ~/.bashrc

# Run tests
bash tests/run_tests.sh

# Lint
shellcheck pvm.sh pvm-exec install.sh bash_completion tests/*.sh
```

## Code Style

- POSIX shell with bash/zsh extensions only where documented
- Main script is sourced, not executed — exports a `pvm()` shell function
- Internal helpers prefixed with `pvm_` (e.g., `pvm_download`, `pvm_version_path`)
- Use tabs for indentation in shell scripts (see .editorconfig)
- All error messages go to stderr
- All commands must work offline when reasonable (cache, local operations)
- Follow nvm's patterns where applicable

### File Size Guidelines

| Metric | Guideline | Action if exceeded |
|--------|-----------|-------------------|
| File length | 800 lines | Split subcommands into helpers |
| Function length | 80 lines | Extract helpers |
| Nesting depth | 5 levels | Flatten with early returns |

## Project Structure

```
pvm.sh              # Main sourced script (~2500 lines)
pvm-exec            # Subshell exec helper
install.sh          # Bootstrap installer
bash_completion     # Tab completion for bash
tests/
  run_tests.sh      # Test runner
  test_*.sh         # Individual test files
  fixtures/         # Test fixtures
docs/
  decisions/        # Architecture Decision Records
  architecture.md   # Architecture documentation
```

## Testing

- All new features must include tests
- Bug fixes must include a regression test
- Tests run via `bash tests/run_tests.sh`
- Tests use a temporary `PVM_DIR` to avoid polluting the user's environment
- No external dependencies in tests — mock network calls
- Prefer integration tests over mocks — but HTTP calls to pike.lysator.liu.se must be mocked

## Error Handling

- **Do not suppress errors.** `set -e` is not used (sourced script), but every command must check its exit code.
- **Errors must be distinguishable from success.** Functions return non-zero on failure.
- **Fail at the boundary.** Validate downloaded content, filesystem operations, user input.
- **No lying.** If a download partially fails, do not pretend the installation succeeded.
- **User-facing errors** go to stderr with a `pvm:` prefix.

## CI/CD

CI uses separate workflow files, one concern per file.

| Workflow | Purpose |
|----------|---------|
| `ci.yml` | Shellcheck + run tests |
| `commit-lint.yml` | Conventional commit enforcement |
| `changelog-check.yml` | Changelog update enforcement (PRs only) |
| `blob-size-policy.yml` | Rejects oversized files (PRs only) |

## Agent Behavior

When an AI agent is working in this repository:

1. **Always create PRs for changes.** Do not push directly to `main`.
2. **Run shellcheck and tests before requesting review.**
3. **Read before editing.** Shell scripts have subtle context dependencies.
4. **Test offline behavior.** pvm must work without network for local operations.
5. **One concern per change.** A PR should address one issue or feature.
6. **Update CHANGELOG.md** for every user-facing change.
7. **Follow the sourced-script pattern.** Do not add `#!/usr/bin/env bash` to pvm.sh.

8. **Clean up after yourself.** Remove dead code and unused variables.

9. **Zero lint tolerance.** All shellcheck findings (info, warning, error) must be zero before requesting review. Do not leave pre-existing warnings unfixed. If a finding is a false positive, suppress it with a `# shellcheck disable=SCXXXX` comment and explain why.

## Conventions

### Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

### Branches

Follow [Conventional Branch](https://github.com/nickshanks347/conventional-branch) naming:

```
<type>/<short-description>
```

### Changelog

Follow [Keep a Changelog](https://keepachangelog.com/). Update `CHANGELOG.md` under `[Unreleased]` for every user-facing change.
