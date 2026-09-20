# Audio Transcription Suite installer

## Download

Installers are distributed through [GitHub Releases](https://github.com/Kradores/audio-transcription-suite/releases), not stored in Git. The first release, **v0.1.0**, is being prepared as a draft; its downloads are not public until it is published. After publication, [latest release](https://github.com/Kradores/audio-transcription-suite/releases/latest) is the stable download entry point.

Choose one installer for your GPU:

| GPU | Release asset |
| --- | --- |
| AMD | `AudioTranscriptionSuite-Amd-Setup-0.1.0.exe` |
| NVIDIA | `AudioTranscriptionSuite-Nvidia-Setup-0.1.0.exe` |

These installers are **unsigned**. Windows may display an unknown-publisher or SmartScreen warning. Download only from this repository's releases and compare the download's SHA-256 hash with the corresponding entry in the release's `SHA256SUMS.txt`:

```powershell
Get-FileHash .\AudioTranscriptionSuite-Amd-Setup-0.1.0.exe -Algorithm SHA256
# For NVIDIA, use AudioTranscriptionSuite-Nvidia-Setup-0.1.0.exe instead.
```

Checksums verify file integrity; they are not a publisher signature. See [deployment notes](docs/deployment.md) for the release workflow and validation limits.

## Installation

Run the installer matching your GPU as your normal Windows user, with Claude fully closed:

- AMD: `AudioTranscriptionSuite-Amd-Setup-0.1.0.exe`
- NVIDIA: `AudioTranscriptionSuite-Nvidia-Setup-0.1.0.exe`

Requires Windows x64, internet access, and a GPU/driver compatible with the selected service build.

Setup installs the selected Audio Transcription Service 0.1.0 GPU build and CoreMcp executable, downloads the latest official Claude x64 MSIX, verifies its Authenticode signature and Anthropic publisher, installs it for the current user, and merges `mcpServers.coremcp` into Claude's packaged configuration. Other settings, MCP servers, and unrelated CoreMcp environment variables are preserved. Existing configuration is backed up alongside the original before an atomic replacement. Invalid JSON is never overwritten.

Default locations:

| Component | Location |
| --- | --- |
| Audio service | `%LOCALAPPDATA%\Programs\AudioTranscriptionService` |
| CoreMcp | `%LOCALAPPDATA%\Programs\AudioTranscriptionSuite\CoreMcp.Server.exe` |
| Transcript database | `%LOCALAPPDATA%\AudioTranscriptionService\data\transcripts.db` |
| Claude config | `%LOCALAPPDATA%\Packages\<Claude package family>\LocalCache\Roaming\Claude\claude_desktop_config.json` |
| Suite log | `%LOCALAPPDATA%\AudioTranscriptionSuite\logs\setup.log` |

The wizard lets you select a different database path. For an existing service installation, this must match `database.path` in `%LOCALAPPDATA%\AudioTranscriptionService\config\config.yaml`; relative paths are resolved under `%LOCALAPPDATA%\AudioTranscriptionService`. The service's existing configuration is retained by its own installer.

The AMD and NVIDIA variants share the same installation locations and are alternatives, not side-by-side installations. If switching GPU builds on an existing installation, update the retained service configuration to match the new GPU runtime before starting it. A fresh installation uses the selected service installer's default configuration.

Start Audio Transcription Service from the Start menu after setup to create the database and record transcripts, then open Claude. CoreMcp is launched by Claude on demand; it is not a Windows background service. Claude sign-in remains interactive. Optional Cowork Windows features are not enabled.

If installation fails, setup displays an incomplete status and returns exit code 1. Inspect the log, fix the reported issue, and rerun. Successfully installed components remain installed. Downloads require access to Anthropic's servers. Windows application deployment policies may block MSIX installation.

The suite uninstaller removes CoreMcp and its setup scripts; it retains Claude configuration and transcript data. Remove the `coremcp` entry manually if you uninstall the suite. Claude and Audio Transcription Service can each be uninstalled separately in Windows Settings.

## Build and checks

Keep `CoreMcp.Server.exe` and the desired `AudioTranscriptionService-<Gpu>-Setup-0.1.0.exe` in the root folder. Install Inno Setup 6.7 or newer, then run `./Build-Installer.ps1 -Gpu Amd` for AMD or `./Build-Installer.ps1 -Gpu Nvidia` for NVIDIA (the default). Each build produces a separate output file. Alternatively pass `-Compiler <path-to-ISCC.exe>` or set `INNO_SETUP_COMPILER`. The build prints a SHA-256 checksum. Replacing payloads requires reviewing names/version metadata in the build and installer scripts.

Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./tests/Test-Configuration.ps1` to check the configuration merge under Windows PowerShell 5.1. Tests use disposable files under `tests`; they do not change installed applications or your Claude settings.

The full installation should also be tested on a clean Windows x64 machine with internet access and a compatible driver for the selected GPU. Building and configuration tests do not validate real Claude deployment, GPU operation, or account sign-in.

Official Claude deployment reference: https://support.claude.com/en/articles/12622703-deploy-claude-desktop-for-windows
