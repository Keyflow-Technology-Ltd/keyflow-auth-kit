# KeyflowAuthKit

Shared iOS client for the Keyflow federated-auth service at
`auth.keyflowae.com`. Used by LeadsFlow, DealsFlow, and LeaseFlow iOS
apps — replaces each app's per-product Keychain / Auth / Token code
with one tested implementation.

## Features

- `KeyflowAuthClient` — HTTP wrapper over the 10 auth-service endpoints
  (signin, refresh, signout, memberships, handoff, password reset,
  session status).
- `FederatedAuthService` — `@MainActor ObservableObject` façade for
  SwiftUI. Manages `isSignedIn`, `currentUser`, and handles Keychain
  persistence.
- `KeyflowKeychain` — minimal Keychain accessor scoped by a service
  name (so each product's install has isolated storage).
- `DeviceIdentity` — per-install UUID for the `deviceId` claim.
- Typed errors (`KeyflowAuthError`) with pattern-matchable cases.

## Install

Add to `project.yml` (xcodegen):

```yaml
packages:
  KeyflowAuthKit:
    url: https://github.com/Keyflow-Technology-Ltd/keyflow-auth-kit
    from: "0.1.0"

targets:
  LeadsFlow:
    dependencies:
      - package: KeyflowAuthKit
```

Or in Xcode: File → Add Package Dependencies → URL
`https://github.com/Keyflow-Technology-Ltd/keyflow-auth-kit`.

## Usage

```swift
import KeyflowAuthKit

let auth = FederatedAuthService(
    product: .leadsflow,
    keychainService: "com.keyflow.leadsflow.federated",
)

try await auth.signIn(email: "user@example.com", password: "…")
// auth.isSignedIn == true
// auth.currentUser -> FederatedAuthUser
// auth.accessToken() -> "eyJ…"

// Later, request a handoff token to open DealsFlow already signed in:
let handoff = try await auth.mintHandoff(to: .dealsflow)
// Open: dealsflow://handoff?token=\(handoff.handoffToken)
```

## Status

- Shipped as Phase 2, Step 3 of the SSO rollout (see
  `Keyflow/docs/sso-architecture.md`). Apps adopt it incrementally —
  each iOS app keeps its legacy signin path during rollout and adds a
  `useFederatedAuth` flag to switch.
