# Security Policy

## Supported Versions

Security fixes are provided for the latest stable release and the immediately preceding minor release when a safe backport is practical. Pre-release builds receive fixes only on the newest pre-release line.

## Reporting

Do not open a public issue for a suspected vulnerability, credential leak, unsafe archive extraction, command-injection path, malicious asset/dependency, or privacy flaw. Use GitHub's private vulnerability-reporting flow for `pin705/Codex-Game-Maker` and include affected version, platform, reproduction, impact, and sanitized logs.

Never attach signing keys, store credentials, personal data, unpublished game assets, or access tokens. Maintainers should acknowledge a complete report within five business days, publish a remediation decision, and coordinate disclosure after a fix is available.

## Trust Boundaries

Codex Game Maker executes project commands and may download Godot archives. Release-pinned Godot downloads require the SHA-512 values recorded in the version policy before extraction. Game projects remain responsible for their own third-party dependencies, generated-asset rights, secrets, online services, signing authorities, and store credentials.
