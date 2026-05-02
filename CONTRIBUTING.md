# Contributing

Thank you for your interest in contributing. This document covers the conventions used in this project.

## Quick Start

1. Fork the repository
2. Create a feature branch (see [Branch Naming](#branch-naming))
3. Make your changes
4. Run `shellcheck pvm.sh pvm-exec install.sh bash_completion tests/*.sh`
5. Run `bash tests/run_tests.sh`
6. Update [CHANGELOG.md](./CHANGELOG.md) under `[Unreleased]`
7. Open a Pull Request

## Branch Naming

Follow [Conventional Branch](https://github.com/nickshanks347/conventional-branch) naming:

```
<type>/<short-description>
```

| Type | Use for |
|------|----------|
| `feature/`, `feat/` | New functionality |
| `bugfix/`, `fix/` | Bug fixes |
| `hotfix/` | Urgent production fixes |
| `chore/` | Maintenance, deps, tooling |
| `docs/` | Documentation only |
| `refactor/` | Code restructuring without behavior change |
| `perf/` | Performance improvements |
| `test/` | Adding or updating tests |
| `ci/` | CI/CD pipeline changes |
| `release/` | Release preparation |

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

## Changelog

Update [CHANGELOG.md](./CHANGELOG.md) under the `[Unreleased]` section for every user-facing change.

## Pull Requests

- Keep PRs focused on a single concern
- Include tests for new behavior
- Ensure CI passes (shellcheck + tests)
- Reference related issues in the PR description
- Follow the PR template when opening a PR
