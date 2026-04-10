#!/usr/bin/env python3
"""
Telegram Gate — deterministic enforcement of Telegram acknowledgment.

Closes a gate when a Telegram message arrives. Blocks all non-Telegram
tools until Claude sends a react/reply to acknowledge the message.
"""
import json
import os
import sys

STATE_FILE = "/tmp/claude_telegram_gate.json"

TELEGRAM_COMM_TOOLS = {
    # server: delivery path (recommended — used by start.sh)
    "mcp__telegram__react",
    "mcp__telegram__reply",
    "mcp__telegram__edit_message",
    # plugin: delivery path (legacy)
    "mcp__plugin_telegram_telegram__react",
    "mcp__plugin_telegram_telegram__reply",
    "mcp__plugin_telegram_telegram__edit_message",
}


def read_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def write_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)


def handle_prompt_submit(data):
    """Close the gate when a Telegram message arrives."""
    prompt = data.get("prompt") or data.get("user_prompt") or ""
    session_id = data.get("session_id", "")

    if 'source="' in prompt and "telegram" in prompt:
        write_state({
            "session_id": session_id,
            "gate": "closed",
            "consecutive_blocks": 0,
        })
    sys.exit(0)


def handle_pre_tool_use(data):
    """Block non-Telegram tools when the gate is closed."""
    tool_name = data.get("tool_name", "")
    session_id = data.get("session_id", "")

    state = read_state()
    if state is None:
        sys.exit(0)

    # Stale state from a different session — ignore
    stored = state.get("session_id", "")
    if stored and session_id and stored != session_id:
        os.remove(STATE_FILE)
        sys.exit(0)

    gate = state.get("gate", "open")
    blocks = state.get("consecutive_blocks", 0)

    # Telegram communication tools open the gate
    if tool_name in TELEGRAM_COMM_TOOLS:
        write_state({
            "session_id": session_id,
            "gate": "open",
            "consecutive_blocks": 0,
        })
        sys.exit(0)

    # Always allow ToolSearch — needed to load deferred telegram tool schemas
    if tool_name == "ToolSearch":
        sys.exit(0)

    # Gate open — allow everything
    if gate == "open":
        sys.exit(0)

    # Gate closed — block non-Telegram tools
    # Circuit breaker: force open after 3 consecutive blocks
    if blocks >= 3:
        write_state({
            "session_id": session_id,
            "gate": "open",
            "consecutive_blocks": 0,
        })
        json.dump({
            "systemMessage": (
                "WARNING: Gate forced open after 3 blocks. "
                "You should have sent a Telegram react and status "
                "message first. Please send one now."
            )
        }, sys.stdout)
        sys.exit(0)

    # Block — increment counter and return error
    write_state({
        "session_id": session_id,
        "gate": "closed",
        "consecutive_blocks": blocks + 1,
    })
    print(
        "BLOCKED: You MUST send a Telegram acknowledgment before "
        "making other tool calls. Call "
        "mcp__telegram__react with emoji \U0001f440 AND "
        "mcp__telegram__reply with a brief status "
        "message (e.g. 'Working on it...'). Then retry your work.",
        file=sys.stderr,
    )
    sys.exit(2)


if __name__ == "__main__":
    data = json.load(sys.stdin)
    event = data.get("hook_event_name", "")

    if len(sys.argv) > 1:
        event = sys.argv[1]

    if event == "UserPromptSubmit":
        handle_prompt_submit(data)
    elif event == "PreToolUse":
        handle_pre_tool_use(data)
    else:
        sys.exit(0)
