# GitHub Releases

The distribution channel is [Kradores/audio-transcription-suite releases](https://github.com/Kradores/audio-transcription-suite/releases). Executables, compiled installers, preview output, and logs are excluded from Git.

## v0.2.1 assets

- `AudioTranscriptionSuite-Amd-Setup-0.2.1.exe`
- `AudioTranscriptionSuite-Nvidia-Setup-0.2.1.exe`
- `SHA256SUMS.txt`

Use the existing compiled installers without rebuilding or signing. Preserve the older v0.1.0 draft and upstream service releases. The suite bundles service 0.2.0 and CoreMcp; it downloads the latest official Claude MSIX at installation time and verifies its signature and Anthropic publisher.

## Requirements and usage

Windows 11 x64, internet access, and a compatible GPU/driver are required. AMD targets supported gfx1031 hardware and was validated upstream on Radeon RX 6800M. Other AMD architectures are not assumed compatible. AMD and NVIDIA builds are alternatives, not side-by-side installations.

Run normally from an administrator-enabled Windows account with Claude closed. Approve Claude’s elevation prompt using the same account; alternate administrator credentials are rejected. Suite installers are unsigned and may trigger SmartScreen or unknown-publisher warnings. Checksums verify integrity, not publisher identity.

See the [getting-started guide](getting-started.md) for regular-user instructions.

## Publish and verify

1. Check that the remote branch has no conflicting changes and the version tag does not already exist.
2. Commit source and documentation only, then push the commit and matching version tag.
3. Verify existing installer hashes and write `dist/SHA256SUMS.txt`: lowercase SHA-256, two spaces, exact filename, one line per installer.
4. Create a draft release and upload both installers and the checksum file.
5. Compare uploaded names, sizes, and GitHub SHA-256 digests with local files. If a digest is unavailable, download the asset and hash it.
6. Publish as the latest stable release and verify public metadata and download URLs. Do not replace published binaries; use a new version for binary changes.

## Validation record

The user successfully tested AMD and NVIDIA suite 0.2.0 installations. Suite 0.2.1 passed automated configuration, deployment, streaming-download, and simulated wizard success/failure checks, plus visual layout inspection. Real installation, UAC/MSIX deployment, and GPU transcription have not yet been verified specifically with suite 0.2.1.
