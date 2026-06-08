# Dockerfile for freezetext-mcp — Linux container build for Glama evaluation.
#
# The MCP server speaks JSON-RPC over stdio. Tool *definitions* (tools/list) are
# served without the FreezeText macOS app running; tool *calls* require the app
# on the host (http://localhost:${FREEZETEXT_API_PORT:-9876}) and will return a
# graceful "FreezeText is not running" error inside this container.
FROM swift:6.0

WORKDIR /app
COPY . .

RUN swift build -c release --product FreezeTextMCP

ENTRYPOINT ["/app/.build/release/FreezeTextMCP"]
