# FreezeText MCP Server

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![MCP](https://img.shields.io/badge/protocol-MCP-purple.svg)](https://modelcontextprotocol.io)
[![juergenkoller-software/freezetext-mcp MCP server](https://glama.ai/mcp/servers/juergenkoller-software/freezetext-mcp/badges/score.svg)](https://glama.ai/mcp/servers/juergenkoller-software/freezetext-mcp)

**OCR anything on your Mac screen from Claude, Cursor, or any MCP client.**

This is the official [Model Context Protocol](https://modelcontextprotocol.io) server for [**FreezeText**](https://store.juergenkoller.software/en/apps/freezetext) — a free native macOS app that freezes the screen and extracts text via Apple Vision OCR. Whether running videos, disappearing popups, protected PDFs, or hover tooltips — FreezeText makes any visible text copyable.

> **You need the FreezeText app installed and running** with its HTTP API enabled (Settings → API). This MCP server talks to the app's local API. Get FreezeText (free) at [store.juergenkoller.software/apps/freezetext](https://store.juergenkoller.software/en/apps/freezetext).

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

All OCR runs locally via Apple Vision Framework — no cloud, no data transmission.

---

## Installation

### Prerequisites

1. **macOS 14 (Sonoma) or later**
2. **FreezeText app installed and running** — [get it free here](https://store.juergenkoller.software/en/apps/freezetext) — with the HTTP API enabled in Settings
3. **Swift 5.9+** (Xcode 15+) if building from source

### Build from source

```bash
git clone https://github.com/juergenkoller-software/freezetext-mcp.git
cd freezetext-mcp
swift build -c release
# Binary: .build/release/FreezeTextMCP
```

### Pre-built binary

See [Releases](https://github.com/juergenkoller-software/freezetext-mcp/releases).

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
        "FREEZETEXT_API_TOKEN": "your-token-if-set"
      }
    }
  }
}
```

`FREEZETEXT_API_TOKEN` is only required if you set an API token in FreezeText's Settings.

### Claude Code

```bash
claude mcp add freezetext /path/to/FreezeTextMCP \
  --env FREEZETEXT_API_PORT=9876
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
| `FREEZETEXT_API_TOKEN` | _(none)_ | Bearer token — only if set in FreezeText Settings |

---

## About FreezeText

FreezeText is a **free** native macOS OCR utility. Highlights:

- **Free**, no subscription, no sign-up
- **Lightning-fast OCR** — Apple Vision Framework, under 0.3 seconds
- **Freeze the screen** — capture text from videos, popups, protected PDFs, hover tooltips
- **Global hotkey** (⌘⇧7)
- **QR code & barcode detection**
- **Searchable history** with color tags + JSON/CSV export
- **HTTP API** (40+ endpoints) — this MCP server is built on it
- **100% local** — no cloud, no data transmission

→ **[Get FreezeText free at store.juergenkoller.software](https://store.juergenkoller.software/en/apps/freezetext)**

---

## License

MIT — see [LICENSE](LICENSE). This MCP server is open source; the FreezeText app is free (proprietary).

## Issues & support

- **MCP server bugs:** [open an issue](https://github.com/juergenkoller-software/freezetext-mcp/issues)
- **App support:** [support@juergenkoller.software](mailto:support@juergenkoller.software)

Built by [Juergen Koller Software GmbH](https://juergenkoller.software).
