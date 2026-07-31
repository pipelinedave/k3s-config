# Cluster Paths

This directory contains cluster-specific GitOps entrypoints.

## Purpose

- Keep one GitHub repository.
- Allow different clusters to reconcile different subsets of manifests.
- Avoid forking and reduce drift.

## Layout

- bigboi: references the full current app set.
- nucy: references Phase 1 only.

## Nucy Wiring

The nucy scaffold includes:

- `clusters/nucy/apps/` with phase-1 Flux Kustomization resources
- `clusters/nucy/apps-kustomization.yaml` (Flux `apps` Kustomization)

After `flux bootstrap` to `./clusters/nucy`, add `apps-kustomization.yaml` to `clusters/nucy/kustomization.yaml` resources so Flux reconciles the phase-1 app set.

These paths are scaffolding only until Flux on a cluster is explicitly bootstrapped to that path.
