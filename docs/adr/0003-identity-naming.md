# ADR 0003: Naming for the Kennel Corp forest and tenant

**Status:** Proposed
**Date:** 2026-10-14

## Context

Hybrid sync only gives users a sign-in name in the cloud domain if the on-premises UPN suffix matches a domain verified in the Entra tenant. The tenant is `thekennel.onmicrosoft.com` (fictional company: Kennel Corp). The owner has a registered domain, `demarzo.dev`, which also hosts a live website.

## Options

| Option | Effect |
|---|---|
| Forest root is `demarzo.dev` itself | Internal clients resolve the public site through the DC and lose it, or the DC has to mirror every public record. Microsoft advises against it |
| Forest root is a subdomain, `corp.demarzo.dev`, with UPN suffix `demarzo.dev` | Internal DNS is authoritative only for `corp`. Users sign in as `user@demarzo.dev`. Public DNS is untouched except for one verification record |
| Non-routable forest such as `kennel.local` | Works, but needs an alternate UPN suffix anyway and is a pattern to avoid |

## Decision

Forest root `corp.demarzo.dev`, NetBIOS name `KENNEL`, additional UPN suffix `demarzo.dev`. Verify `demarzo.dev` in the tenant with a TXT record at the registrar. The DC's DNS forwards to public resolvers.

## Consequences

- A domain verifies in only one tenant at a time. If `demarzo.dev` is already verified in another tenant, remove it there first.
- The verification TXT record is the only public DNS change. It is made by the owner at the registrar and recorded in the lab write-up.
- The website on `demarzo.dev` is not affected.
