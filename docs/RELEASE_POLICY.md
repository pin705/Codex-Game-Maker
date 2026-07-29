# Release Policy

Codex Game Maker uses semantic versioning for the plugin manifest.

- Patch: compatible fixes, validation hardening, and documentation corrections.
- Minor: backward-compatible skills, commands, templates, or optional contracts.
- Major: incompatible plugin, command, project-contract, or migration behavior.

Every stable tag must match the plugin manifest, README status, changelog, and release artifact metadata. Release CI performs clean URL-marketplace installation, plugin validation, cross-platform tests, package hashing, and SBOM generation. Project schema changes require a dry-run migration, backup, migration report, N-1 fixture, and rollback instructions.

The latest stable and immediately previous minor are supported. Deprecations must name the replacement and cannot be removed before the next major release unless continued support is unsafe.

Stable releases do not claim that every generated game is commercially successful. They guarantee the documented workflow and gates; target-device certification, legal decisions, signing, store review, independent taste review, and real-player validation remain release-specific evidence.
