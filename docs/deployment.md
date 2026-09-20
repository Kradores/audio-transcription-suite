# GitHub Releases

The canonical installer distribution channel is [Kradores/audio-transcription-suite releases](https://github.com/Kradores/audio-transcription-suite/releases). Installers and bundled executable payloads are not committed to Git or Git LFS. The repository contains the Suite installer source, build script, tests, and documentation.

## First release

Prepare **Audio Transcription Suite v0.1.0** as a draft targeting the `v0.1.0` source tag, with these three assets:

- `AudioTranscriptionSuite-Amd-Setup-0.1.0.exe`
- `AudioTranscriptionSuite-Nvidia-Setup-0.1.0.exe`
- `SHA256SUMS.txt`

Use the existing files in `dist/` without rebuilding or signing. Both installers are unsigned. Preserve the existing upstream Audio Transcription Service releases. This Suite release bundles the selected service 0.1.0 installer and CoreMcp; setup downloads the latest official Claude x64 MSIX and verifies its signature and Anthropic publisher. Unsigned Suite distribution does not disable that verification.

The installers require Windows x64, internet access, and a compatible GPU and driver. AMD and NVIDIA builds are alternatives, not side-by-side installations. Run as the normal Windows user with Claude closed. Start the audio service after setup, then open Claude and sign in interactively. Windows may show SmartScreen or unknown-publisher warnings for the unsigned installers.

## Preparation and verification

1. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./tests/Test-Configuration.ps1`.
2. Confirm the source commit excludes executable payloads, `dist/`, and test scratch directories. Tag that commit `v0.1.0` and push the source and tag.
3. Calculate SHA-256 hashes of both final installers. Write `dist/SHA256SUMS.txt` as one lowercase hash, two spaces, and the exact asset filename per line.
4. Create the draft release and upload the two installers and checksum file. Do not replace or modify the binaries during release preparation.
5. Verify all three uploaded filenames, byte sizes, and GitHub SHA-256 asset digests against the local files. If an uploaded digest is unavailable, download that asset and calculate its hash for comparison.
6. Confirm the release is still a draft and provide its review link. Publishing is a separate action after review.

Configuration tests and asset integrity checks do not validate real installation, Claude deployment, GPU operation, or account sign-in. Clean-machine Windows x64 installation testing is unverified for this release unless separately recorded.

## Publication

Draft assets are not available to public visitors. After the first stable release is published, use [the latest-release URL](https://github.com/Kradores/audio-transcription-suite/releases/latest) as the stable user-facing download link, and update the README's draft status. Keep published binaries and checksums unchanged; distribute later binary changes under a new version.
