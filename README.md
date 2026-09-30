# Audio Transcription Suite installer

## Download

Installers are distributed through [GitHub Releases](https://github.com/Kradores/audio-transcription-suite/releases/latest), not stored in Git. Get **v0.2.1** from the [release page](https://github.com/Kradores/audio-transcription-suite/releases/tag/v0.2.1), or use [latest release](https://github.com/Kradores/audio-transcription-suite/releases/latest) for the current stable version.

After installation, follow the **[getting-started guide](docs/getting-started.md)** to start transcription and find conversations with Claude.

Choose one installer for your GPU:

| GPU | Release asset |
| --- | --- |
| AMD | `AudioTranscriptionSuite-Amd-Setup-0.2.1.exe` |
| NVIDIA | `AudioTranscriptionSuite-Nvidia-Setup-0.2.1.exe` |

These installers are **unsigned**. Windows may display an unknown-publisher or SmartScreen warning. Download only from this repository's releases and compare the download's SHA-256 hash with the corresponding entry in the release's `SHA256SUMS.txt`:

```powershell
Get-FileHash .\AudioTranscriptionSuite-Amd-Setup-0.2.1.exe -Algorithm SHA256
# For NVIDIA, use AudioTranscriptionSuite-Nvidia-Setup-0.2.1.exe instead.
```

Checksums verify file integrity; they are not a publisher signature. See [deployment notes](docs/deployment.md) for the release workflow and validation limits.

## Installation

Run the installer matching your GPU as your normal Windows user, with Claude fully closed:

- AMD: `AudioTranscriptionSuite-Amd-Setup-0.2.1.exe`
- NVIDIA: `AudioTranscriptionSuite-Nvidia-Setup-0.2.1.exe`

Requires Windows 11 x64, internet access, and a GPU/driver compatible with the selected service build.

Setup installs the selected Audio Transcription Service 0.2.0 GPU build and CoreMcp executable, downloads the latest official Claude x64 MSIX, verifies its Authenticode signature and Anthropic publisher, installs it for the current user, and merges `mcpServers.coremcp` into Claude's packaged configuration. Other settings, MCP servers, and unrelated CoreMcp environment variables are preserved. Existing configuration is backed up alongside the original before an atomic replacement. Invalid JSON is never overwritten.

Default locations:

| Component | Location |
| --- | --- |
| Audio service | `%LOCALAPPDATA%\Programs\AudioTranscriptionService` |
| CoreMcp | `%LOCALAPPDATA%\Programs\AudioTranscriptionSuite\CoreMcp.Server.exe` |
| Transcript database | `%LOCALAPPDATA%\AudioTranscriptionService\data\transcripts.db` |
| Claude config | `%LOCALAPPDATA%\Packages\<Claude package family>\LocalCache\Roaming\Claude\claude_desktop_config.json` |
| Suite log | `%LOCALAPPDATA%\AudioTranscriptionSuite\logs\<run-id>\setup.log` |

The wizard lets you select a different database path. For an existing service installation, this must match `database.path` in `%LOCALAPPDATA%\AudioTranscriptionService\config\config.yaml`; relative paths are resolved under `%LOCALAPPDATA%\AudioTranscriptionService`. The service's existing configuration is retained by its own installer.

The AMD and NVIDIA variants share the same installation locations and are alternatives, not side-by-side installations. If switching GPU builds on an existing installation, update the retained service configuration to match the new GPU runtime before starting it. A fresh installation uses the selected service installer's default configuration.

Start Audio Transcription Service from the Start menu after setup to create the database and record transcripts, then open Claude. CoreMcp is launched by Claude on demand; it is not a Windows background service. Claude sign-in remains interactive. Optional Cowork Windows features are not enabled.

If installation fails, setup displays an incomplete status and returns exit code 1. Inspect the log, fix the reported issue, and rerun. Successfully installed components remain installed. Downloads require access to Anthropic's servers. Windows application deployment policies may block MSIX installation.

The suite uninstaller removes CoreMcp and its setup scripts; it retains Claude configuration and transcript data. Remove the `coremcp` entry manually if you uninstall the suite. Claude and Audio Transcription Service can each be uninstalled separately in Windows Settings.

## Build and checks

Keep `CoreMcp.Server.exe` and the desired `AudioTranscriptionService-<Gpu>-Setup-0.2.0.exe` in the root folder. Install Inno Setup 6.7 or newer, then run `./Build-Installer.ps1 -Gpu Amd` for AMD or `./Build-Installer.ps1 -Gpu Nvidia` for NVIDIA (the default). Each build produces a separate output file. Alternatively pass `-Compiler <path-to-ISCC.exe>` or set `INNO_SETUP_COMPILER`. The build prints a SHA-256 checksum. Service and suite versions are defined once in Build-Installer.ps1 and passed to Inno Setup. Each output has a matching .exe.sha256 checksum file.

Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./tests/Test-Configuration.ps1` to check the configuration merge under Windows PowerShell 5.1. Tests use disposable files under `tests`; they do not change installed applications or your Claude settings.

The full installation should also be tested on a clean Windows 11 x64 machine with internet access and a compatible driver for the selected GPU. Building and configuration tests do not validate real Claude deployment, GPU operation, or account sign-in.

Official Claude deployment reference: https://support.claude.com/en/articles/12622703-deploy-claude-desktop-for-windows

## Administrator prompt

Launch setup normally from an administrator-enabled Windows account. Setup requests elevation only for Claude installation and checks that the elevated process has the same Windows user identity. Supplying another administrator account is rejected before registering Claude. Standard accounts requiring another administrator identity are not supported by this installation flow. The service and MCP configuration continue in the original user process. Canceling elevation leaves setup incomplete and does not proceed to service installation or configuration.

Each run keeps a separate log directory containing setup.log, claude-install.log (if the helper starts under the correct identity), and audio-service-setup.log (if that step runs). Retry logs do not overwrite previous runs. Claude installation precedes the service installation so elevation failures are caught earlier.

Run tests/Test-ClaudeDeployment.ps1 with Windows PowerShell 5.1 for mocked elevation-result checks and the real helper identity guard. Real UAC and MSIX deployment require a Windows installation test; these checks do not install software.

## Service 0.2.0

Both service installers include the default small Whisper model. Model provisioning is handled by the service installer; a fresh installation can start transcription without downloading that model. Existing service configuration, transcript data, and existing model directories are preserved. Additional models can be installed through the controller using Install Model.

The AMD build targets supported gfx1031 hardware and was validated upstream on Radeon RX 6800M. Other AMD architectures are not assumed compatible. Windows 11 x64 is the supported and validated platform.

Upstream release notes: https://github.com/Kradores/audio-transcription-service/releases/tag/v0.2.0

## Live setup progress (suite 0.2.1)

Preparation progress covers MCP installation and payload extraction only. The following page shows a checklist and the current step: downloading Claude, verifying the download, awaiting administrator approval, installing Claude, installing Audio Transcription Service, and updating configuration. Downloads show measured MB and percentage when the server supplies a total size; other stages use an animated indicator. Completion requires a successful process exit and completed configuration. Failure identifies the stage and the run log. Child installers are not canceled from this page.

The internal ATS_PROGRESS line protocol is consumed by Inno Setup using ExecAndLogOutput. Run tests/Test-Progress.ps1 for streaming checks. Compile tests/ProgressPreview.iss and run the resulting dist/tests/ProgressPreview.exe to simulate the actual wizard without installing applications. Add /fail=1 for a simulated failure or /VERYSILENT /SUPPRESSMSGBOXES /LOG for unattended assertions. These checks do not validate real UAC or MSIX deployment.
