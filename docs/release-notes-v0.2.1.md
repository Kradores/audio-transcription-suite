# Audio Transcription Suite v0.2.1

## What’s new

- Live installation checklist with completed steps and a clear current-stage display.
- Measured Claude download progress in MB and percentage when total size is available; animated progress for other steps.
- Failed-stage identification and separate logs for every run.
- Administrator approval for Claude installation while keeping configuration tied to the original Windows user.
- Bundled **Audio Transcription Service 0.2.0**, including the default **small** Whisper model, ready without an initial model download.

## Getting started

1. Find **Audio Transcription Service** in the Windows **Start menu** and open it.
2. Click **Start** to begin transcription.
3. Open **Claude Desktop**, sign in if needed, and ask about something that has been transcribed:
   - “Summarize the conversation from today around 10 AM.”
   - “Find the conversation where we discussed holiday plans.”
   - “What did we decide about the project deadline?”
4. Try different questions and see what you can find 🙂
5. Click **Stop** in Audio Transcription Service whenever you want transcription to stop.

**The service can run throughout the day and does not need a live call. While running, it transcribes both system audio and microphone, including audio outside calls. You choose when to start and stop it. Conversations that were never transcribed cannot be retrieved.**

If Claude says it has no memory, ask: “Use CoreMcp to search my recorded audio transcripts.” These recordings are separate from Claude’s built-in memory and chat history.

[Read the full getting-started guide](https://github.com/Kradores/audio-transcription-suite/blob/v0.2.1/docs/getting-started.md).

## Choose your installer

- **NVIDIA:** `AudioTranscriptionSuite-Nvidia-Setup-0.2.1.exe`
- **AMD gfx1031:** `AudioTranscriptionSuite-Amd-Setup-0.2.1.exe`. The upstream service was validated on Radeon RX 6800M; other AMD architectures are not assumed compatible.

Requires **Windows 11 x64**, internet access, a compatible GPU/driver, and an administrator-enabled Windows account. Close Claude before setup. Launch normally and approve Claude’s administrator prompt using the **same account**; different administrator credentials are rejected.

Suite installers are **unsigned**. Windows may display SmartScreen or unknown-publisher warnings. Verify downloads against `SHA256SUMS.txt`. The downloaded Claude package is checked for a valid signature and Anthropic publisher.

## Validation

Both AMD and NVIDIA **suite 0.2.0** installations were successfully tested by the user. **Suite 0.2.1** passed automated configuration, deployment, streaming-download, and simulated wizard success/failure checks, plus visual layout inspection. Real installation and GPU transcription testing specifically for 0.2.1 remains outstanding.
