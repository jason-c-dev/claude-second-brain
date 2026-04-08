import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const PORT = parseInt(process.env.WEBHOOK_PORT ?? "8788");

const mcp = new Server(
  { name: "webhook-channel", version: "1.0.0" },
  {
    capabilities: {
      tools: {},
      experimental: { "claude/channel": {} },
    },
    instructions: [
      "Events from webhook-channel are scheduled tasks or external system alerts.",
      "Each event has a path (e.g. /briefing, /reconcile) and a JSON body.",
      "Check the path to determine what action to take.",
      "See the CLAUDE.md ## Webhook Events section for handling instructions.",
      "When a webhook task requires sending results to the user, use the Telegram reply tool.",
    ].join("\n"),
  }
);

mcp.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: [] }));
mcp.setRequestHandler(CallToolRequestSchema, async () => ({
  content: [{ type: "text", text: "no tools" }],
  isError: true,
}));

const transport = new StdioServerTransport();
await mcp.connect(transport);

const httpServer = Bun.serve({
  port: PORT,
  hostname: process.env.WEBHOOK_HOST ?? "127.0.0.1",
  async fetch(req) {
    const url = new URL(req.url);

    if (req.method === "GET" && url.pathname === "/health") {
      return new Response(JSON.stringify({ status: "ok" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (req.method !== "POST") {
      return new Response("method not allowed", { status: 405 });
    }

    let body: string;
    try {
      body = await req.text();
    } catch {
      return new Response("bad request", { status: 400 });
    }

    try {
      await mcp.notification({
        method: "notifications/claude/channel",
        params: {
          content: body,
          meta: {
            source: "webhook-channel",
            path: url.pathname,
            method: req.method,
            timestamp: new Date().toISOString(),
          },
        },
      });
    } catch (err) {
      process.stderr.write(`webhook-channel: failed to push event: ${err}\n`);
      return new Response("delivery failed", { status: 500 });
    }

    return new Response("accepted", { status: 202 });
  },
});

process.stderr.write(
  `webhook-channel: listening on http://127.0.0.1:${PORT}\n`
);

function shutdown(): void {
  process.stderr.write("webhook-channel: shutting down\n");
  httpServer.stop();
  process.exit(0);
}
process.stdin.on("end", shutdown);
process.stdin.on("close", shutdown);
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
