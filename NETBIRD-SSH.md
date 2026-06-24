# NetBird SSH setup + break-glass runbook

## Normal fleet access (after reinstall)

1. Install NetBird: `winget install Netbird.Netbird`
2. `netbird up` → authenticates via SSO (Zitadel OIDC) — no key to restore
3. `ssh ubuntu@zammad` (or any alias from `~/.ssh/config`) works immediately

No private key needed for fleet hosts. Identity is proven via OIDC; NetBird
issues short-lived certificates transparently.

## Break-glass (NetBird or Zitadel outage)

One emergency keypair lives in Keeper: **"Break-glass SSH"**.

1. Open Keeper → copy the private key → save to `~/.ssh/id_ed25519_breakglass`
2. `chmod 600 ~/.ssh/id_ed25519_breakglass` (WSL/Git Bash)
3. `ssh -i ~/.ssh/id_ed25519_breakglass ubuntu@<direct-ip>`

Direct IPs and Hetzner rescue console credentials are also in Keeper.

Delete the local key file when done.

## Automation / service accounts

Use a dedicated machine identity or NetBird `--disable-ssh-auth` mode.
Never reuse your personal identity for automation.
