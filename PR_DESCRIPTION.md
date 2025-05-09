# Set up Dex Authentication for Choremane

This PR implements proper user login and identity management for Choremane using Dex as an OpenID Connect provider.

## Changes

### Kubernetes Configuration (k3s-config repo)

1. **Dex Setup**:
   - Added FluxCD Kustomization for Dex in `/apps/dex.yaml`
   - Updated Dex ConfigMap to include Choremane client configuration
   - Set up proper namespace and dependencies

2. **Choremane Configuration**:
   - Added OAuth ConfigMap and Secret for storing authentication parameters
   - Created deployment patches to inject authentication environment variables into the backend
   - Updated FluxCD Kustomizations to depend on Dex

### Application Code (choremane repo)

1. **Backend Changes**:
   - Added OpenID Connect and OAuth2 authentication using Dex
   - Created auth.py for token validation and user management
   - Added auth_routes.py for authentication endpoints
   - Updated main.py to include authentication middleware
   - Added User model for storing authenticated user information
   - Created database table for users

2. **Frontend Changes**:
   - Updated the auth store to handle token management
   - Added Login and AuthCallback pages
   - Updated the router to handle authentication state
   - Enhanced axios interceptors to handle token refreshing

## How to Test

1. The Dex deployment will be available at https://dex.stillon.top
2. Choremane users will be redirected to Dex for authentication
3. Dex will delegate to Google for actual user authentication
4. Upon successful login, users will be redirected back to Choremane with proper tokens

## Notes

- Ensure Google OAuth credentials are properly configured in the Dex secret
- Session secret and client secret should be changed for production use
- The frontend application may need to be updated with the proper redirect URIs

## Remaining Work

- Add token refresh endpoint to the backend
- Implement more granular permission controls
- Consider adding RBAC for administrative functions
