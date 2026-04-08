import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { existsSync } from "fs";
import { execSync } from "child_process";
import { join } from "path";
import { tmpdir } from "os";
import { randomBytes } from "crypto";

const STT_PATH = process.env.STT_PATH ?? "whisper-cli";
const STT_MODEL = process.env.STT_MODEL;

const server = new McpServer({
  name: "voice-tools",
  version: "1.0.0",
});

server.tool(
  "voice_transcribe",
  "Transcribe an audio file (OGG, WAV, MP3) to text using whisper.cpp. " +
    "Use this when a Telegram voice message arrives — download it first " +
    "with the Telegram download_attachment tool, then pass the path here.",
  {
    path: z.string().describe("Absolute path to the audio file"),
  },
  async ({ path }) => {
    if (!STT_MODEL) {
      return {
        content: [
          {
            type: "text",
            text: "STT_MODEL not configured. Set the environment variable to the path of your whisper.cpp GGML model.",
          },
        ],
        isError: true,
      };
    }

    if (!existsSync(path)) {
      return {
        content: [{ type: "text", text: `File not found: ${path}` }],
        isError: true,
      };
    }

    const tmpWav = join(
      tmpdir(),
      `voice-stt-${randomBytes(4).toString("hex")}.wav`
    );

    try {
      // Convert to 16kHz mono WAV
      execSync(
        `ffmpeg -y -i "${path}" -ar 16000 -ac 1 -f wav "${tmpWav}" 2>/dev/null`
      );

      // Run whisper
      const result = execSync(
        `"${STT_PATH}" -m "${STT_MODEL}" -f "${tmpWav}" --no-timestamps -l en 2>/dev/null`,
        { encoding: "utf8", timeout: 60000 }
      );

      return {
        content: [{ type: "text", text: result.trim() }],
      };
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      return {
        content: [{ type: "text", text: `Transcription failed: ${msg}` }],
        isError: true,
      };
    } finally {
      try {
        execSync(`rm -f "${tmpWav}"`);
      } catch {}
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
