# ADR 0007: Android application ID remains unchanged until confirmed

## Status

Accepted

## Context

The master plan proposes `com.hopetv.iptvplayer` as the Android application ID. Changing package identity affects signing continuity and store/distribution identity.

## Decision

Do **not** change `android/app/build.gradle.kts` applicationId/namespace from `com.example.iptv` until the owner explicitly confirms the permanent ID in `OWNER_CONFIG.md`.

## Consequences

- Customer release builds must wait for confirmation.
- Documentation may list the proposal as unconfirmed only.
