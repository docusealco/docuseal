# Incident Response Plan (IRP)

Status: Draft

## Purpose

This Incident Response Plan (IRP) defines the steps the project maintainer(s) will follow when handling security incidents related to the `oauth2` gem. It is written for a small project with a single primary maintainer and is intended to be practical, concise, and actionable.

## Scope

Applies to security incidents that affect the `oauth2` codebase, releases (gems), CI/CD infrastructure related to building and publishing the gem, repository credentials, or any compromise of project infrastructure that could impact users.

## Key assumptions
- This project is maintained primarily by a single maintainer.
- Public vulnerability disclosure is handled via Tidelift (see `SECURITY.md`).
- The maintainer will act as incident commander unless otherwise delegated.

## Contact & Roles

- Incident Commander: Primary maintainer (repo owner). Responsible for coordinating triage, remediation, and communications.
- Secondary Contact: (optional) A trusted collaborator or organization contact if available.

### If you are an external reporter
- Do not publicly disclose details of an active vulnerability before coordination via Tidelift.
- See `SECURITY.md` for Tidelift disclosure instructions. If the reporter has questions and cannot use Tidelift, they may open a direct encrypted report as described in `SECURITY.md` (if available) or email the maintainer contact listed in the repository.

## Incident Handling Workflow (high level)
1. Identification & Reporting
   - Reports may arrive via Tidelift, issue tracker, direct email, or third-party advisories.
   - Immediately acknowledge receipt (within 24-72 hours) via the reporting channel.

2. Triage & Initial Assessment (first 72 hours)
   - Confirm the report is not duplicative and gather: reproducer, affected versions, attack surface, exploitability, and CVSS-like severity estimate.
   - Verify the issue against the codebase and reproduce locally if possible.
   - Determine scope: which versions are affected, whether the issue is in code paths executed in common setups, and whether a workaround exists.

3. Containment & Mitigation
   - If a simple mitigation or workaround (configuration change, safe default, or recommended upgrade) exists, document it clearly in the issue/Tidelift advisory.
   - If immediate removal of a release is required (rare), consult Tidelift for coordinated takedown and notify package hosts if applicable.

4. Remediation & Patch
   - Prepare a fix in a branch with tests and changelog entries. Prefer minimal, well-tested changes.
   - Include tests that reproduce the faulty behavior and demonstrate the fix.
   - Hardening: add fuzz tests, input validation, or additional checks as appropriate.

5. Release & Disclosure
   - Coordinate disclosure through Tidelift per `SECURITY.md` timelines. Aim for a coordinated disclosure and patch release to minimize risk to users.
   - Publish a patch release (increment gem version) and an advisory via Tidelift.
   - Update `CHANGELOG.md` and repository release notes with non-sensitive details.

6. Post-Incident
   - Produce a short postmortem: timeline, root cause, actions taken, and follow-ups.
   - Add/adjust tests and CI checks to prevent regressions.
   - If credentials or infrastructure were compromised, rotate secrets and audit access.

## Severity classification (guidance)
- High/Critical: Remote code execution, data exfiltration, or any vulnerability that can be exploited without user interaction. Immediate action and prioritized patching.
- Medium: Privilege escalation, sensitive information leaks that require specific conditions. Patch in the next release cycle with advisory.
- Low: Minor information leaks, UI issues, or non-exploitable bugs. Fix normally and include in the next scheduled release.

## Preservation of evidence
- Preserve all reporter-provided data, logs, and reproducer code in a secure location (local encrypted storage or private branch) for the investigation.
- Do not publish evidence that would enable exploitation before coordinated disclosure.

## Communication templates
Acknowledgement (to reporter)

"Thank you for reporting this issue. I've received your report and will triage it within 72 hours. If you can, please provide reproduction steps, affected versions, and any exploit PoC. I will coordinate disclosure through Tidelift per the project's security policy."

Public advisory (after patch is ready)

"A security advisory for oauth2 (versions X.Y.Z) has been published via Tidelift. Please upgrade to version A.B.C which patches [brief description]. See the advisory for details and recommended mitigations."

## Runbook: Quick steps for a maintainer to patch and release
1. Create a branch: `git checkout -b fix/security-brief-description`
2. Reproduce the issue locally and add a regression spec in `spec/`.
3. Implement the fix and run the test suite: `bundle exec rspec` (or the project's preferred test command).
4. Bump version in `lib/oauth2/version.rb` following semantic versioning.
5. Update `CHANGELOG.md` with an entry describing the fix (avoid exploit details).
6. Commit and push the branch, open a PR, and merge after approvals.
7. Build and push the gem: `gem build oauth2.gemspec && gem push pkg/...` (coordinate with Tidelift before public push if disclosure is coordinated).
8. Publish a release on GitHub and ensure the Tidelift advisory is posted.

## Operational notes
- Secrets: Use local encrypted storage for any sensitive reporter data. If repository or CI secrets may be compromised, rotate them immediately and update dependent services.
- Access control: Limit who can publish gems and who has admin access to the repo. Keep an up-to-date list of collaborators in a secure place.

## Legal & regulatory
- If the incident involves user data or has legal implications, consult legal counsel or the maintainers' employer as appropriate. The maintainer should document the timeline and all communications.

## Retrospective & continuous improvement
After an incident, perform a brief post-incident review covering:
- What happened and why
- What was done to contain and remediate
- What tests or process changes will prevent recurrence
- Assign owners and deadlines for follow-up tasks

## References
- See `SECURITY.md` for the project's official disclosure channel (Tidelift).

## Appendix: Example checklist for an incident
- [ ] Acknowledge report to reporter (24-72 hours)
- [ ] Reproduce and classify severity
- [ ] Prepare and test a fix in a branch
- [ ] Coordinate disclosure via Tidelift
- [ ] Publish patch release and advisory
- [ ] Postmortem and follow-up actions
