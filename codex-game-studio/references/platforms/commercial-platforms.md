# Commercial Platform Requirements

Verify the live official documentation at release time. Store policies, SDK levels, asset sizes, privacy declarations, and certification rules change independently of this plugin.

## Web

- Reproducible release export, HTTPS hosting, MIME headers, compression, cache invalidation, persistent storage, focus/audio unlock, browser matrix, memory/threading constraints, accessibility, and privacy/cookie decisions.

## Windows, macOS, Linux

- Release artifact and clean-machine smoke test for every supported architecture/OS.
- Package identity, save/log locations, dependencies, controller/display matrix, crash symbols, installer/update behavior, signing decision.
- macOS requires an explicit code-signing and notarization decision for public distribution.

## Android

- Current Godot/Android toolchain, target API, AAB/APK policy, package identity, signing, permissions, lifecycle, thermal/memory/device matrix, Data Safety, content rating, target audience, billing/ads rules when applicable.
- Official starting point: https://developer.android.com/google/play/requirements/target-sdk

## iOS and Apple Platforms

- Current SDK/Xcode compatibility, bundle identity, signing/provisioning, archive validation, lifecycle, privacy details, age rating, accessibility declarations, commerce, review notes, and TestFlight evidence.
- Official starting points: https://developer.apple.com/app-store/submitting/ and https://developer.apple.com/app-store/review/guidelines/

## Steam

- Depot/build configuration, launch options, redistributables, supported OS/controller claims, store page, screenshots/trailer, current capsule/library assets, content survey, pricing, review-ready build, and optional services only when integrated and tested.
- Official starting points: https://partner.steamgames.com/doc/store/page and https://partner.steamgames.com/doc/store/assets

## Consoles

- Treat all certification details as platform-confidential. Block until the authorized developer has program access, SDK/toolchain, credentials, current requirements, target hardware, submission owner, and certification evidence.

## Evidence Rule

For each declared target, store the official source URL and verification date alongside artifact hash, build/smoke command IDs, device matrix, signing result, packaging result, store-review state, and owner approval.
