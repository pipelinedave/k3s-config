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
