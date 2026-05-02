# ADR 0001: Sourced Shell Script

## Status

Accepted

## Context

PVM needs to manage PATH and environment variables in the user's current shell session. A compiled binary or executed script cannot modify the parent shell's environment.

## Decision

Follow nvm's architecture: `pvm.sh` is a POSIX-compliant shell script that is sourced into the shell session. It exports a single `pvm()` shell function with internal helpers prefixed `pvm_`.

## Consequences

- **Positive**: Zero dependencies (no compiler, no runtime). Works on any POSIX system. Can manipulate PATH directly.
- **Positive**: Proven model — nvm has used this successfully for years.
- **Negative**: No static type checking. Limited test tooling compared to compiled languages.
- **Negative**: Shell compatibility requires care (bash vs zsh vs POSIX sh).
