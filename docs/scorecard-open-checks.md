# Scorecard checks left open

These OpenSSF Scorecard alerts stay open on the repository. Nothing in this file dismisses or hides them.

Checked on 2026-11-07. Open in this repository:

| Check | What Scorecard reported |
| --- | --- |
| Code-Review | 0 of the last 12 changesets had an approving review |
| Fuzzing | No fuzzer integration |
| CII-Best-Practices | No OpenSSF Best Practices badge |
| Maintained | Repository was created within the last 90 days |

Code-Review stays open because the repository has one maintainer, so a second person does not approve the changesets. The default-branch ruleset still requires a pull request.

Fuzzing stays open because this repository publishes workflows and CI images. It does not ship a library that parses untrusted input in-process.

CII-Best-Practices stays open because no OpenSSF Best Practices badge is claimed.

Maintained stays open until the repository is older than the window Scorecard uses. The alert is left to age.
