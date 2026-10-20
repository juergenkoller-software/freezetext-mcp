# FreezeText MCP Server

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![MCP](https://img.shields.io/badge/protocol-MCP-purple.svg)](https://modelcontextprotocol.io)
[![juergenkoller-software/freezetext-mcp MCP server](https://glama.ai/mcp/servers/juergenkoller-software/freezetext-mcp/badges/score.svg)](https://glama.ai/mcp/servers/juergenkoller-software/freezetext-mcp)

**OCR anything on your Mac screen from Claude, Cursor, or any MCP client.**

This is the official [Model Context Protocol](https://modelcontextprotocol.io) server for [**FreezeText**](https://store.juergenkoller.software/en/apps/freezetext?mtm_source=mcp&mtm_medium=agent&mtm_campaign=freezetext-mcp&mtm_content=github-readme) — a native macOS app that freezes the screen and extracts text via Apple Vision OCR. Whether running videos, disappearing popups, protected PDFs, or hover tooltips — FreezeText makes any visible text copyable.

> **You need the FreezeText app installed and running** with its HTTP API enabled (Settings → API → “Enable API Server”). This MCP server talks to the app's local API. FreezeText is free to try for 14 days, then a one-time purchase. Get it at [store.juergenkoller.software/apps/freezetext](https://store.juergenkoller.software/en/apps/freezetext?mtm_source=mcp&mtm_medium=agent&mtm_campaign=freezetext-mcp&mtm_content=github-readme).

---

## What you can do

> "Claude, OCR whatever is on my screen right now and summarize it."
>
> "Cursor, run OCR on this screenshot (base64) and extract the invoice number."
>
> "Search my FreezeText history for everything containing 'tracking number'."

The MCP server exposes **12 tools**:

| Category | Tools |
|---|---|
| **Capture & OCR** | `capture_screen` (freeze + OCR), `capture_region` (OCR a specific rect), `ocr_image` (OCR a base64 image) |
| **History** | `list_history`, `search_history`, `get_history_entry`, `add_history`, `delete_history_entry`, `clear_history`, `export_history` (JSON/CSV) |
| **OCR config** | `get_ocr_languages`, `set_ocr_languages` |

All OCR runs locally via Apple Vision Framework, without a cloud service.

---

## Installation

### Prerequisites

1. **macOS 14 (Sonoma) or later**
2. **FreezeText app installed and running** — [get it here](https://store.juergenkoller.software/en/apps/freezetext?mtm_source=mcp&mtm_medium=agent&mtm_campaign=freezetext-mcp&mtm_content=github-readme) (14-day free trial, then a one-time purchase)
3. **HTTP API enabled** in FreezeText → Settings → API (“Enable API Server”, off by default)
4. **Swift 5.9+** (Xcode 15+) if building from source

### Build from source

```bash
git clone https://github.com/juergenkoller-software/freezetext-mcp.git
cd freezetext-mcp
swift build -c release
# Binary: .build/release/FreezeTextMCP
```

### Pre-built binary

There is no pre-built macOS binary yet; build from source as shown above. The binary attached to [Releases](https://github.com/juergenkoller-software/freezetext-mcp/releases) is a static Linux x86_64 build for container-based MCP registries such as Glama; it does not run on macOS.

---

## Configuration

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "freezetext": {
      "command": "/path/to/FreezeTextMCP",
      "env": {
        "FREEZETEXT_API_PORT": "9876",
        "FREEZETEXT_API_TOKEN": "your-token-here"
      }
    }
  }
}
```

`FREEZETEXT_API_TOKEN` is required: FreezeText answers every request without the right token with HTTP 401. Copy it from **FreezeText → Settings → API** (“API Token”), or generate one there.

### Claude Code

```bash
claude mcp add freezetext /path/to/FreezeTextMCP \
  --env FREEZETEXT_API_PORT=9876 \
  --env FREEZETEXT_API_TOKEN=your-token-here
```

### Cursor / other MCP clients

Same pattern — stdio MCP server, configured via the two env vars above.

---

## How it works

```
┌────────────────┐  JSON-RPC stdio   ┌────────────────┐   HTTP(+Bearer)   ┌────────────────┐
│  Claude/Cursor │ ───────────────►  │ FreezeTextMCP  │ ────────────────► │  FreezeText.app│
│  (MCP client)  │ ◄───────────────  │   (this repo)  │ ◄──────────────── │  (port 9876)   │
└────────────────┘                    └────────────────┘                   └────────────────┘
```

This is a full MCP server (built on the official [`modelcontextprotocol/swift-sdk`](https://github.com/modelcontextprotocol/swift-sdk)) that maps MCP tool calls to FreezeText's local HTTP API. The OCR engine (Apple Vision), screen capture, and history storage live in the FreezeText app.

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `FREEZETEXT_API_PORT` | `9876` | Port of FreezeText's local HTTP API |
| `FREEZETEXT_API_TOKEN` | _(none)_ | Bearer token from FreezeText → Settings → API (required) |

---

## Errors

Every refusal comes back as an MCP error (`isError: true`) with a sentence the agent can act on:

| Situation | What the bridge reports |
|---|---|
| FreezeText not running, or API switched off | FreezeText is not reachable at `http://localhost:<port>`; open FreezeText and turn on “Enable API Server” |
| Token wrong or missing (HTTP 401) | Set `FREEZETEXT_API_TOKEN` to the token in FreezeText → Settings → API |
| No token generated yet (HTTP 503) | Generate one in FreezeText → Settings → API |
| Any other HTTP error | Status code and FreezeText's error text, e.g. a missing Accessibility permission |

Before version 0.2.0 the bridge ignored the HTTP status, so a wrong token looked like a successful call. `search_history` also never reached the app, because its query string was encoded into the path.

---

## About FreezeText

FreezeText is a native macOS OCR utility. Highlights:

- **14-day free trial**, then a one-time purchase — no subscription
- **Lightning-fast OCR** — Apple Vision Framework, under 0.3 seconds
- **Freeze the screen** — capture text from videos, popups, protected PDFs, hover tooltips
- **Global hotkey** (⌘⇧7)
- **QR code & barcode detection**
- **Searchable history** with color tags + JSON/CSV export
- **HTTP API** (80+ endpoints) — this MCP server is built on it
- **24 languages**
- **Local OCR** — recognition runs on your Mac, without a cloud service; the licence check needs an internet connection at least every 40 days

→ **[Get FreezeText at store.juergenkoller.software](https://store.juergenkoller.software/en/apps/freezetext?mtm_source=mcp&mtm_medium=agent&mtm_campaign=freezetext-mcp&mtm_content=github-readme)**

---

## License

MIT — see [LICENSE](LICENSE). This MCP server is open source; the FreezeText app is commercial.

## Issues & support

- **MCP server bugs:** [open an issue](https://github.com/juergenkoller-software/freezetext-mcp/issues)
- **App support:** [support@juergenkoller.software](mailto:support@juergenkoller.software)

Built by [Juergen Koller Software GmbH](https://juergenkoller.software).
