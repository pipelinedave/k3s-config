# Traefik to Nginx Ingress Migration Plan

This document outlines the step-by-step plan for migrating from Traefik to Nginx Ingress Controller on our K3s cluster.

## Migration Steps

### Phase 1: Setup and Testing (Current Phase)

1. ✅ Deploy Nginx Ingress Controller with proper RBAC permissions
2. ✅ Temporarily disable Traefik by scaling down to 0 replicas
3. ✅ Set up a test application with Nginx Ingress to verify functionality
4. ✓ Verify that cert-manager integration works with Nginx Ingress

### Phase 2: Gradual Migration

5. Create a list of all applications currently using Traefik ingress
6. For each application:
   - Update the Ingress resource to use `ingressClassName: nginx`
   - Update any Traefik-specific annotations to their Nginx equivalents
   - Test the application to ensure it works with Nginx
   - Document any application-specific configuration needed

### Phase 3: Finalization

7. Once all applications have been migrated:
   - Verify all applications are functioning correctly with Nginx
   - Permanently remove Traefik from the cluster
   - Update the documentation to reflect the new Nginx-based ingress setup

## Reference Documentation

- For detailed annotation mappings, examples, and configuration guidance, refer to the [Traefik to Nginx Migration Guide](./traefik-to-nginx-migration.md)

## Alternative Approaches

### If Scaling Down Traefik Doesn't Work

If you encounter issues with scaling down Traefik (due to immutable fields or other constraints), consider these alternatives:

1. **Use ingress class selection**: Configure Nginx to only process ingresses with `ingressClassName: nginx` while Traefik continues to process its own. Migrate applications one by one.

2. **Port conflict resolution**: Change the Traefik service to use different nodePort values, allowing both controllers to run simultaneously.

3. **Service annotation approach**: Use service annotations to control which load balancer handles which service/port.

The current approach preserves all Traefik configuration while just reducing replicas to 0, ensuring you can easily scale it back up if needed.

## Application Migration Tracker

| Application | Namespace | Current Status | Migration Status | Notes |
|-------------|-----------|----------------|------------------|---------|
| nginx-test | default | ✅ Using Nginx | Complete | Test application |
| choremane-prod | choremane-prod | Using Traefik | Not Started | |
| choremane-staging | choremane-staging | Using Traefik | Not Started | |
| dex | dex | Using Traefik | Not Started | |
| docspell | docspell | Using Traefik | Not Started | |
| gotify | gotify | Using Traefik | Not Started | |
| linkding | linkding | Using Traefik | Not Started | |
| memodawg | memodawg | Using Traefik | Not Started | |
| metube | metube | Using Traefik | Not Started | |
| picoshare | picoshare | Using Traefik | Not Started | |