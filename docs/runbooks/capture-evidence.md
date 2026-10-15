# Capturing lab evidence

The Microsoft 365 E5 trial tenant was created 2026-10-14 and lasts 30 days, so it ends **around 2026-11-13**. Confirm the exact date in the Microsoft 365 admin center under Billing. After that, features that need a paid licence (Conditional Access, Identity Protection, PIM, governance) can no longer be demonstrated, so each lab has to be recorded while it is still working.

The on-prem side is different: the Windows evaluation licences on dc01, ws01 and ws02 run into 2027 ([provisioning runbook](provision-lab-vms.md)), so AD and DNS work stays reproducible after the tenant is gone.

## Rules

- **Capture while you do it.** Take the evidence at the moment the setting works, not afterwards. A lab with no evidence is not marked done.
- **Record failures too.** The "What went wrong" section of the [lab template](../labs/TEMPLATE.md) is the most useful part of a write-up.
- **Mark a feature unavailable if it is.** If a feature does not appear or is blocked by licensing in the trial, write that down with the date. That is a factual finding.
- **State expected versus actual** for every verification step.

## Redaction (before anything is committed)

Raw captures go in `docs/images/raw/`, which is gitignored. Only redacted copies go in `docs/images/`.

Redact or crop:
- Tenant ID, directory ID, subscription and object IDs
- The admin account name and any real email address
- Tenant-bound URLs that contain an ID
- Passwords, secrets, certificates, one-time codes and recovery keys
- Public IP addresses, and your home network details

Fine to leave visible: `thekennel.onmicrosoft.com`, Kennel Corp, `demarzo.dev`, `kennelcorp.demarzo.dev`, the 10.12.41.0/24 lab addresses, and fictional user names.

Exported JSON or CSV must be read through once before it is committed. Exports often carry tenant IDs, object IDs and UPNs of the admin account.

## Per-lab checklist

Each row is one thing to capture. Tick it only when the file is saved. Group the write-ups by the SC-300 skill areas used in the [README](../../README.md#exam-coverage). If the course labs are ordered differently, keep the order of the course and note the skill area in each write-up header.

### Implement identities in Entra ID
- [ ] Tenant overview with the IDs hidden, and the licences assigned (Billing and Licenses page)
- [ ] Custom domain `demarzo.dev` shown as verified (the DNS record type used for verification, not the token value)
- [ ] Users and groups created: list view plus one group with dynamic membership rules
- [ ] On-prem forest: `Get-ADForest` and `Get-ADDomain` output on dc01, DNS zone and DHCP scope screenshots
- [ ] Sync: the Entra Connect or Cloud Sync health page showing a successful run, plus one user that exists in both places
- [ ] Hybrid join: `dsregcmd /status` output on the Windows 11 client, with device and tenant IDs redacted
- [ ] A test sign-in as a synced user, and the sign-in log entry for it

### Authentication and access management
- [ ] Authentication methods policy, with which methods are enabled for which groups
- [ ] MFA registration and one real MFA prompt (the prompt screen and the sign-in log entry)
- [ ] Each Conditional Access policy: the policy summary, report-only results, then the enforced result. Export the policy JSON for each (read it first)
- [ ] The **What If** tool result for at least one user and app combination
- [ ] Self-service password reset configuration and a completed reset
- [ ] Identity Protection: risk policies, and a simulated risky sign-in with the resulting risk detection
- [ ] PIM: an eligible role assignment, an activation with justification, and the audit entry

### Workload identities
- [ ] App registration: redirect URIs, API permissions with the consent state, and which secret or certificate type was used (never the value)
- [ ] Enterprise application: user assignment and the single sign-on configuration
- [ ] A managed identity, with the role assignment it was given and a call that used it

### Identity governance
- [ ] Access review: the configuration, the reviewer's decision screen, and the applied result
- [ ] Entitlement management: catalog, access package, and a request moving through approval
- [ ] Lifecycle workflows: a workflow definition and a run history entry
- [ ] Terms of use or other governance items from the course, if covered

### Monitoring
- [ ] Sign-in logs and audit logs filtered to show the lab events above
- [ ] Any diagnostic setting configured, and where the logs are sent

## After each lab

1. Fill in [`TEMPLATE.md`](../labs/TEMPLATE.md) as `docs/labs/NN-short-name.md` and add a row to the [labs index](../labs/README.md).
2. Update the [README](../../README.md#exam-coverage) skill-area status and the [roadmap](../roadmap.md) only for what was verified.
3. Stage explicit paths, check the diff for IDs and addresses, then commit.

## One week before the trial ends

- [ ] Every lab with a working feature has a write-up and redacted evidence
- [ ] Exports of Conditional Access, authentication methods and app registrations are saved and read through
- [ ] A list of what could not be demonstrated and why is in the roadmap
- [ ] Decide whether to keep an Entra ID Free tenant for the identity basics, and note in the README which labs need which licence
