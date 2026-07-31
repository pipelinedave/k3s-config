# Nucy Phase 1 Migration Plan

Date: 2026-07-31

## Goal

Move only the daily-use services to nucy while preserving the GitOps workflow:

- chores.stillon.top (choremane-prod)
- share.stillon.top (picoshare)
- ingress and certificate prerequisites

Out of scope for this phase:

- docspell
- family media stack
- adult media stack changes

## GitOps Strategy

Use a single GitHub repository with multi-cluster paths.

- Do not fork.
- Do not repoint current bigboi Flux immediately.
- Add a dedicated nucy cluster path and bootstrap Flux there.

Target structure:

- clusters/bigboi
- clusters/nucy

Phase 1 for nucy should include only:

- nginx-ingress
- cert-manager
- dex (only if required by choremane auth flow)
- choremane-prod
- picoshare

Scaffold created in this repository:

- clusters/bigboi/apps/kustomization.yaml
- clusters/nucy/apps/kustomization.yaml
- clusters/nucy/apps-kustomization.yaml

This scaffold does not change live behavior until Flux is bootstrapped to one of these paths.

Bootstrap target for nucy:

```bash
flux bootstrap github \
	--owner=pipelinedave \
	--repository=k3s-config \
	--branch=main \
	--path=./clusters/nucy \
	--personal
```

After bootstrap, wire phase-1 apps into the nucy Flux root kustomization:

1. Edit `clusters/nucy/kustomization.yaml` and include `apps-kustomization.yaml` in `resources`.
2. Commit and push.
3. Verify Flux applies `apps` in `flux-system` namespace.

Expected `clusters/nucy/kustomization.yaml` resources list:

```yaml
resources:
	- gotk-components.yaml
	- gotk-sync.yaml
	- apps-kustomization.yaml
```

Important:

- Do not change bigboi bootstrap path yet.
- Keep bigboi on its current path during phase 1 validation.

## Networking and Public Reachability

Nucy is behind a FritzBox NAT. Choose one of:

1. Direct publish (if real public IPv4 is available):
- Forward TCP 80 and 443 from FritzBox to nucy.
- Keep standard ingress + cert-manager flow.

2. Tunnel publish (recommended for CGNAT/DS-Lite or simpler exposure):
- Use Cloudflare Tunnel from nucy (outbound connection).
- Use DNS-based routing for stillon.top hosts.

Phase 1 cutover hostnames:

- chores.stillon.top
- share.stillon.top

## Execution Checklist

1. Prepare repo layout for multi-cluster operation.
2. Create nucy phase-1 manifests/path only (minimal app set).
3. Bootstrap k3s on nucy with Traefik disabled.
4. Bootstrap Flux on nucy to clusters/nucy path.
5. Validate prerequisites in order:
- ingress controller ready
- cert-manager ready
- dex ready (if included)
6. Deploy choremane-prod and picoshare.
7. Validate app function internally.
8. Implement selected NAT/public access method.
9. Switch DNS only for chores/share.
10. Keep bigboi running as rollback during soak period.

Current path strategy for this phase:

1. bigboi remains on current Flux path.
2. nucy is bootstrapped to `./clusters/nucy`.
3. Any phase-1 app changes are made once and referenced through the nucy cluster kustomization.

## Bootstrap Command Sequence

Run these in order.

1. Ensure SSH agent/key is active in this terminal session:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add -l
```

2. Install k3s on nucy (Traefik disabled):

```bash
ssh dave@192.168.178.46 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh -'
```

3. Confirm k3s is healthy on nucy:

```bash
ssh dave@192.168.178.46 'sudo systemctl is-active k3s && sudo k3s kubectl get nodes -o wide'
```

4. Pull kubeconfig locally for admin access (temporary file/context):

```bash
mkdir -p ~/.kube
ssh dave@192.168.178.46 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/config-nucy
sed -i 's/127.0.0.1/192.168.178.46/' ~/.kube/config-nucy
KUBECONFIG=~/.kube/config-nucy kubectl get nodes
```

5. Create required namespaces manually (repository policy):

```bash
KUBECONFIG=~/.kube/config-nucy kubectl create namespace choremane-prod --dry-run=client -o yaml | KUBECONFIG=~/.kube/config-nucy kubectl apply -f -
KUBECONFIG=~/.kube/config-nucy kubectl create namespace picoshare --dry-run=client -o yaml | KUBECONFIG=~/.kube/config-nucy kubectl apply -f -
KUBECONFIG=~/.kube/config-nucy kubectl create namespace dex --dry-run=client -o yaml | KUBECONFIG=~/.kube/config-nucy kubectl apply -f -
KUBECONFIG=~/.kube/config-nucy kubectl create namespace cert-manager --dry-run=client -o yaml | KUBECONFIG=~/.kube/config-nucy kubectl apply -f -
```

6. Bootstrap Flux for nucy path:

```bash
KUBECONFIG=~/.kube/config-nucy flux bootstrap github \
	--owner=pipelinedave \
	--repository=k3s-config \
	--branch=main \
	--path=./clusters/nucy \
	--personal
```

7. Commit the post-bootstrap `clusters/nucy/kustomization.yaml` update adding `apps-kustomization.yaml`, then push.

8. Validate Flux reconciliation:

```bash
KUBECONFIG=~/.kube/config-nucy flux get kustomizations -A
KUBECONFIG=~/.kube/config-nucy kubectl get pods -A
```

## Success Criteria

- Flux on nucy reports Ready for phase-1 kustomizations.
- chores.stillon.top serves choremane-prod from nucy.
- share.stillon.top serves picoshare from nucy.
- No required phase-1 service still depends on bigboi.

## Rollback Plan

- Keep bigboi cluster active until nucy soak is successful.
- Revert DNS for chores/share back to bigboi if needed.
- Keep data snapshots before cutover for fast restore.

## Notes from Current Discovery

- bigboi k3s admin client cert had expired and was restored by k3s restart on 2026-07-31.
- nucy currently runs Docker workloads and has constrained RAM, so phase-1 minimal scope is mandatory.

## Live Progress (2026-07-31)

Completed:

- k3s installed on nucy (`v1.36.2+k3s1`) with Traefik disabled.
- Flux bootstrapped to `./clusters/nucy`.
- Nucy scaffold committed and pushed through `main`.
- Platform prerequisites added and reconciled:
	- cert-manager controller stack (Running)
	- sealed-secrets controller CRD installed and controller running with fixed image tag `0.32.1`
- Sealed-secrets key material from bigboi imported into nucy so dex-related secrets can decrypt.
- `picoshare` fixed and Ready on nucy:
	- PVC pinning issue handled in `kustomize/picoshare-nucy` by removing immutable `spec.volumeName`
	- image updated to `docker.io/mtlynch/picoshare:1.4.5`
- `dex` is Ready on nucy.
- `choremane-prod` is Ready on nucy.

Important operational note:

- `choremane-prod` needed runtime secrets (`postgres-secret`, `choremane-oauth-secret`) created directly in the cluster because the existing SealedSecret payload for `choremane-oauth-secret` still could not decrypt on nucy.
- This keeps phase 1 functional, but should be followed by re-sealing these secrets for nucy and committing them so secret management is fully GitOps-managed.

Current Flux status summary:

- Ready: `flux-system`, `platform`, `apps`, `nginx-ingress`, `cert-manager`, `picoshare`, `dex`, `choremane-prod`

## External Exposure and DNS Cutover

Current observed DNS (2026-07-31):

- `stillon.top` -> `161.97.88.129` (bigboi)
- `chores.stillon.top` -> `161.97.88.129` (bigboi)
- `share.stillon.top` -> `161.97.88.129` (bigboi)

Current observed home WAN IPv4 from local environment:

- `92.208.35.4`

### Option A (recommended primary): Direct NAT forwarding to nucy + Porkbun DDNS

Prerequisites:

- Nucy has a reserved/static LAN IP (`192.168.178.46`).
- FritzBox can forward TCP `80` and `443` to nucy.

Router changes:

1. Create a port forward for TCP `80` to `192.168.178.46:80`.
2. Create a port forward for TCP `443` to `192.168.178.46:443`.
3. Disable/adjust any conflicting port forwards still targeting bigboi path.

DNS changes:

1. Update `chores.stillon.top` A record from `161.97.88.129` to `92.208.35.4`.
2. Update `share.stillon.top` A record from `161.97.88.129` to `92.208.35.4`.
3. Keep other hostnames on bigboi unchanged during phase 1.

Automate DNS drift handling (recommended):

1. Ensure Porkbun API access is enabled and create API credentials.
2. Install the updater on nucy:

```bash
ssh -i ~/.ssh/id_ed25519_nuc dave@192.168.178.46 'mkdir -p ~/k3s-config/scripts/systemd'
scp -i ~/.ssh/id_ed25519_nuc scripts/porkbun_ddns_update.sh dave@192.168.178.46:~/k3s-config/scripts/
scp -i ~/.ssh/id_ed25519_nuc scripts/systemd/porkbun-ddns-update.service dave@192.168.178.46:~/k3s-config/scripts/systemd/
scp -i ~/.ssh/id_ed25519_nuc scripts/systemd/porkbun-ddns-update.timer dave@192.168.178.46:~/k3s-config/scripts/systemd/
scp -i ~/.ssh/id_ed25519_nuc scripts/install_porkbun_ddns_timer.sh dave@192.168.178.46:~/k3s-config/scripts/
ssh -i ~/.ssh/id_ed25519_nuc dave@192.168.178.46 'bash ~/k3s-config/scripts/install_porkbun_ddns_timer.sh'
```

3. On nucy, edit `/etc/porkbun-ddns.env` and set real values for:
- `PORKBUN_API_KEY`
- `PORKBUN_SECRET_API_KEY`

4. Trigger first update and verify:

```bash
ssh -i ~/.ssh/id_ed25519_nuc dave@192.168.178.46 'sudo systemctl start porkbun-ddns-update.service && sudo systemctl status porkbun-ddns-update.service --no-pager'
```

5. Confirm DNS now points to current home WAN IP:

```bash
for h in chores.stillon.top share.stillon.top; do
	echo "== $h =="
	getent ahostsv4 "$h" | awk '{print $1}' | sort -u
done
```

Validation after DNS change:

```bash
curl -Ik https://chores.stillon.top
curl -Ik https://share.stillon.top
KUBECONFIG=~/.kube/config-nucy kubectl get certificate -A
KUBECONFIG=~/.kube/config-nucy kubectl get challenges.acme.cert-manager.io -A
```

Expected:

- TLS certificates for `chores.stillon.top` and `share.stillon.top` are `Ready=True`.
- Ingress routes land on nucy services.

Rollback (if needed):

1. Revert `chores.stillon.top` and `share.stillon.top` A records back to `161.97.88.129`.
2. Re-enable old port forward path if disabled.

### Option B: Cloudflare Tunnel

Use this only if you move authoritative DNS for the relevant hostnames to Cloudflare (full zone move or delegated subdomain).

Repository state prepared:

- Flux app resource: `clusters/nucy/apps/cloudflare-tunnel.yaml` (currently `suspend: true`)
- Cloudflared deployment manifests: `kustomize/cloudflare-tunnel/`
- Token sealing helper: `scripts/seal_cloudflared_token.sh`

Activation steps:

1. In Cloudflare Zero Trust, create a tunnel and add public hostnames:
- `chores.stillon.top` -> `http://nginx-ingress.kube-system.svc.cluster.local:80`
- `share.stillon.top` -> `http://nginx-ingress.kube-system.svc.cluster.local:80`

How to get the tunnel token (UI path):

1. Open Cloudflare dashboard.
2. Go to Zero Trust.
3. Go to Networks -> Tunnels.
4. Create or select your tunnel.
5. In tunnel setup/connect flow, choose Docker or Kubernetes connector.
6. Copy the value passed to `--token` (or shown as tunnel token).

Alternative token command (if `cloudflared` CLI is installed and authenticated locally):

```bash
cloudflared tunnel token <tunnel-name>
```

DNS note:

- Yes, you still need DNS records for `chores.stillon.top` and `share.stillon.top`.
- If you add Public Hostnames from the Tunnel UI for a zone managed in the same Cloudflare account, Cloudflare can create/manage those DNS records automatically.
- If not auto-created, create proxied CNAME records for each hostname to `<tunnel-uuid>.cfargotunnel.com`.
- You do not need to point these records to your home public IP when using the tunnel.

2. Export the tunnel token locally and generate a SealedSecret manifest:

```bash
export TUNNEL_TOKEN='paste-token-from-cloudflare'
./scripts/seal_cloudflared_token.sh
```

3. Add the sealed secret file to `kustomize/cloudflare-tunnel/kustomization.yaml`:

```yaml
resources:
	- deployment.yaml
	- cloudflared-token-sealed.yaml
```

4. Unsuspend and reconcile on nucy:

```bash
KUBECONFIG=~/.kube/config-nucy flux resume kustomization cloudflare-tunnel -n flux-system
KUBECONFIG=~/.kube/config-nucy flux reconcile source git flux-system -n flux-system
KUBECONFIG=~/.kube/config-nucy flux reconcile kustomization cloudflare-tunnel -n flux-system
KUBECONFIG=~/.kube/config-nucy kubectl -n kube-system get pods -l app.kubernetes.io/name=cloudflared -o wide
```

5. Validate externally:

```bash
curl -Ik https://chores.stillon.top
curl -Ik https://share.stillon.top
```

If you later prefer direct NAT, Option A remains compatible and can be used without removing the tunnel setup.
