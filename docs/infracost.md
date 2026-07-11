# Infracost — local setup

Terraform cost estimation ([docs](https://www.infracost.io/docs/)). Used by jp-infrastructure
CI for per-PR cost-diff comments; locally useful for pre-PR checks.

## Install

Handled by the Brewfile (`brew "infracost"`). Manual: `brew install infracost`.

## Auth — no plaintext key on disk

Do **not** run `infracost auth login` / `infracost configure set api_key` (both write the key
to `~/.config/infracost/credentials.yml` in plaintext). The zshenv wrapper resolves
`INFRACOST_API_KEY` from 1Password on first use:

- Item: `op://JP Infrastructure/Infracost API Key/credential` (account `joshuaproject`)
- Env var beats the credentials file, so nothing is stored locally.

## Usage

```bash
# cost of current directory's Terraform
infracost breakdown --path .

# diff vs a branch (what the CI comment shows per PR)
infracost diff --path . --compare-to infracost-base.json

# generate the base snapshot first
infracost breakdown --path . --format json --out-file infracost-base.json
```

In jp-infrastructure, CI does this automatically per PR (4 env legs, sticky comments,
`--tag infracost-<env>`). Vendor assessment: jp-infrastructure
`docs/vendor-assessments/infracost-alignment-report-2026-07-11.md` (approve-with-conditions;
only HCL-derived resource attributes leave the machine — no secrets, no state).

## Telemetry

`INFRACOST_SELF_HOSTED_TELEMETRY=false` disables CLI telemetry if desired. Self-hosting the
Cloud Pricing API is documented (github.com/infracost/cloud-pricing-api) if pricing lookups
should ever stay on-network.
