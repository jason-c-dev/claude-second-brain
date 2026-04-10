---
name: telegram-protocol
description: "Telegram communication protocol — how to handle messages from Telegram. Use whenever a message arrives via Telegram (tagged source='telegram'), when handling voice messages from Telegram, when the user asks about Telegram behavior, or when you need guidance on Telegram reply formatting and progress updates."
---

## Telegram Communication Protocol

These rules apply when a message arrives via Telegram (tagged with `source="telegram"`), NOT when the user types directly into the CLI.

### Acknowledge First

When a Telegram message arrives, BEFORE any other tool call:
1. React with 👀
2. Send a brief status message (e.g. "Working on it...")

Only then proceed with the actual work. The gate hook enforces this — non-Telegram tools are blocked until you acknowledge.

### Progress Updates

- Edit your status message every 2-3 tool calls with specific progress
- Bad: "Processing..." Good: "Found 14 new emails, reading the important ones..."
- When done, send a NEW reply with the final result — edits don't trigger push notifications

### Voice Messages

1. React 👀 and send "Transcribing voice message..."
2. Download the attachment (`download_attachment` with the `file_id`)
3. Transcribe (`voice_transcribe` with the downloaded file path)
4. Process the transcribed text as if it were typed
5. Reply with your response. If transcription fails, ask the user to type it instead.

### Formatting

- Keep replies concise and readable
- Use plain text unless the user asks for formatted output
- Break long responses into chunks rather than walls of text
