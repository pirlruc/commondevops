# Scanner exceptions

Dependabot alerts that stay open because the pinned tool has no release that
clears them. Review each row on or before its date.

| Package | Pin | Why | Review |
| --- | --- | --- | --- |
| mcp | 1.29.0 | semgrep 1.185.0 requires `mcp==1.29.0`. No newer semgrep release accepts `mcp>=1.30.0`. | 2027-02-13 |
| opentelemetry-api | 1.37.0 | semgrep 1.185.0 requires `opentelemetry-api~=1.37.0`. | 2027-02-13 |

The alerts are in `docker/ci-lint/requirements.txt` and `scripts/requirements.txt`.
SC-TRIAGE-001 covers donor binaries. This row is the same idea for a Python
tool whose own lock forbids the fix.
