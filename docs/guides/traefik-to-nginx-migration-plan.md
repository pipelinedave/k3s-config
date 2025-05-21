# Traefik to Nginx Ingress Migration Plan

This document outlines the step-by-step plan for migrating from Traefik to Nginx Ingress Controller on our K3s cluster.

## Migration Steps

### Phase 1: Setup and Testing (Current Phase)

1. ✅ Deploy Nginx Ingress Controller with proper RBAC permissions
2. ✅ Temporarily disable Traefik by scaling down to 0 replicas
3. ✅ Modify Traefik service to:
   - Change from LoadBalancer to ClusterIP
   - Change ports to avoid conflicts (8080/8443)
   - Remove nodePorts
4. ✅ Set up a test application with Nginx Ingress to verify functionality
5. ✓ Verify that cert-manager integration works with Nginx Ingress

### Phase 2: Gradual Migration

6. Create a list of all applications currently using Traefik ingress
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

### Issues and Solutions

#### K3s ServiceLoadBalancer DaemonSet

With K3s, when services of type LoadBalancer are created, K3s creates a corresponding "svclb-" DaemonSet. We found that even after scaling down the Traefik deployment to 0 replicas, the `svclb-traefik` DaemonSet was still running and binding to ports 80/443, causing port conflicts with our Nginx Ingress controller.

Our solution involves three steps:
1. Scale down the Traefik deployment to 0 replicas
2. Change the Traefik service from LoadBalancer to ClusterIP
3. Change the Traefik service ports to non-standard ports (8080/8443) to avoid any conflicts

This combined approach ensures that:
- Traefik pods are not running
- K3s removes the svclb-traefik DaemonSet (because the service is no longer LoadBalancer)
- Even if there are any lingering references, they point to non-conflicting ports

## Alternative Approaches

If you encounter issues with the current approach (due to immutable fields or other constraints), consider these alternatives:

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