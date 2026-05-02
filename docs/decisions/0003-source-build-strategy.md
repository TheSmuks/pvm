# ADR 0003: Source Build Strategy

## Status

Accepted

## Context

Not all Pike versions have prebuilt binaries for all platforms. Users on uncommon architectures or older Pike versions need a way to install Pike.

## Decision

Provide `--source` flag for `pvm install` to build from source. When no matching binary is found, automatically fall back to source build. Source builds download `Pike-v{VERSION}.tar.gz`, extract, and run `make -j$(nproc) && make install prefix=~/.pvm/versions/{VERSION}`.

## Consequences

- **Positive**: PVM works on any platform with a C compiler.
- **Positive**: Users can explicitly request source builds for reproducibility.
- **Negative**: Source builds require build dependencies (gcc, make, etc.).
- **Negative**: Source builds are significantly slower than binary downloads.
- **Negative**: Build failures are harder to diagnose than download failures.
