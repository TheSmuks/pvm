## What's Changed

* fix(ls): add current/default markers and fix pattern matching by @TheSmuks in https://github.com/TheSmuks/pvm/pull/3

## Bug Fixes

- `pvm ls` now shows `(current)` and `(default)` markers for installed versions
- `pvm ls <pattern>` correctly matches partial version strings (e.g., `1732` matches `8.0.1732`)

**Full Changelog**: https://github.com/TheSmuks/pvm/compare/v0.2.0...v0.2.1