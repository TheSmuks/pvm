# ADR 0002: Binary Slug Matching

## Status

Accepted

## Context

Pike distributes prebuilt binaries with naming pattern `Pike-v{VERSION}-{OS}-{KERNEL_VERSION}-{ARCH}`. The kernel version in the slug varies across builds and platforms, making exact matching impossible.

## Decision

Use glob-style matching: fetch the version directory listing from `pike.lysator.liu.se`, then match `Pike-v{VER}-{OS}-*-{ARCH}`. Select the best match based on OS and architecture detected at runtime.

## Consequences

- **Positive**: Works regardless of kernel version in the binary slug.
- **Positive**: Simple implementation using shell glob patterns.
- **Negative**: Requires fetching the directory listing to discover available binaries.
- **Negative**: May match multiple binaries; need tie-breaking logic (latest kernel version).
