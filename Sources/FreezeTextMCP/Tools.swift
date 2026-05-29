import Foundation
import MCP

// MARK: - Schema helpers

func schema(_ props: [String: Value], required: [String] = []) -> Value {
    var obj: [String: Value] = [
        "type": .string("object"),
        "properties": .object(props)
    ]
    if !required.isEmpty {
        obj["required"] = .array(required.map { .string($0) })
    }
    return .object(obj)
}

func prop(_ type: String, _ desc: String) -> Value {
    .object(["type": .string(type), "description": .string(desc)])
}

// MARK: - Tool definitions

let allTools: [Tool] = [
    Tool(name: "capture_screen",
         description: "Freezes the screen and recognizes text via OCR (Apple Vision). Returns the recognized text from the current screen.",
         inputSchema: schema([:])),

    Tool(name: "capture_region",
         description: "Captures a specific screen region and recognizes its text via OCR. Coordinates in screen points.",
         inputSchema: schema([
            "x": prop("number", "X coordinate of the region's top-left corner"),
            "y": prop("number", "Y coordinate of the region's top-left corner"),
            "width": prop("number", "Width of the region"),
            "height": prop("number", "Height of the region")
         ], required: ["x", "y", "width", "height"])),

    Tool(name: "ocr_image",
         description: "Runs OCR on a provided base64-encoded image (PNG or JPEG) and returns the recognized text.",
         inputSchema: schema([
            "image": prop("string", "Base64-encoded PNG or JPEG image data")
         ], required: ["image"])),

    Tool(name: "list_history",
         description: "Lists all captured-text history entries (id, text, displayName, timestamp, colorTag).",
         inputSchema: schema([:])),

    Tool(name: "search_history",
         description: "Searches the capture history by text. Optional sorting by date or text.",
         inputSchema: schema([
            "query": prop("string", "Search term (matches text and display name)"),
            "sort": prop("string", "Sort field: date or text"),
            "order": prop("string", "Sort order: asc or desc")
         ])),

    Tool(name: "get_history_entry",
         description: "Returns a single history entry by its UUID.",
         inputSchema: schema([
            "id": prop("string", "UUID of the history entry")
         ], required: ["id"])),

    Tool(name: "add_history",
         description: "Adds a text entry to the capture history.",
         inputSchema: schema([
            "text": prop("string", "The text to store"),
            "displayName": prop("string", "Optional display name for the entry")
         ], required: ["text"])),

    Tool(name: "delete_history_entry",
         description: "Deletes a history entry by its UUID.",
         inputSchema: schema([
            "id": prop("string", "UUID of the history entry to delete")
         ], required: ["id"])),

    Tool(name: "clear_history",
         description: "Deletes all history entries.",
         inputSchema: schema([:])),

    Tool(name: "export_history",
         description: "Exports the full capture history as JSON or CSV.",
         inputSchema: schema([
            "format": prop("string", "Export format: json or csv (default json)")
         ])),

    Tool(name: "get_ocr_languages",
         description: "Returns the currently configured OCR recognition languages.",
         inputSchema: schema([:])),

    Tool(name: "set_ocr_languages",
         description: "Sets the OCR recognition languages (e.g. en-US, de-DE).",
         inputSchema: schema([
            "languages": .object([
                "type": .string("array"),
                "items": .object(["type": .string("string")]),
                "description": .string("List of language codes, e.g. [\"en-US\", \"de-DE\"]")
            ])
         ], required: ["languages"])),
]

// MARK: - Tool dispatch

func handleTool(_ params: CallTool.Parameters, client: FreezeTextClient) async throws -> CallTool.Result {
    let args = params.arguments ?? [:]

    switch params.name {
    case "capture_screen":
        let r = try await client.post("/capture")
        return .init(content: [.text(jsonStr(r))])

    case "capture_region":
        let body: [String: Any] = [
            "x": args["x"]?.doubleValue ?? 0,
            "y": args["y"]?.doubleValue ?? 0,
            "width": args["width"]?.doubleValue ?? 0,
            "height": args["height"]?.doubleValue ?? 0
        ]
        let r = try await client.post("/capture/region", body: body)
        return .init(content: [.text(jsonStr(r))])

    case "ocr_image":
        let r = try await client.post("/ocr", body: ["image": str(args["image"])])
        return .init(content: [.text(jsonStr(r))])

    case "list_history":
        let r = try await client.get("/history")
        return .init(content: [.text(jsonStr(r))])

    case "search_history":
        var q = "/history/search?"
        var parts: [String] = []
        if let query = args["query"]?.stringValue, !query.isEmpty {
            parts.append("q=" + (query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""))
        }
        if let sort = args["sort"]?.stringValue { parts.append("sort=\(sort)") }
        if let order = args["order"]?.stringValue { parts.append("order=\(order)") }
        q += parts.joined(separator: "&")
        let r = try await client.get(q)
        return .init(content: [.text(jsonStr(r))])

    case "get_history_entry":
        let r = try await client.get("/history/\(str(args["id"]))")
        return .init(content: [.text(jsonStr(r))])

    case "add_history":
        var body: [String: Any] = ["text": str(args["text"])]
        if let dn = args["displayName"]?.stringValue { body["displayName"] = dn }
        let r = try await client.post("/history", body: body)
        return .init(content: [.text(jsonStr(r))])

    case "delete_history_entry":
        let r = try await client.delete("/history/\(str(args["id"]))")
        return .init(content: [.text(jsonStr(r))])

    case "clear_history":
        let r = try await client.delete("/history")
        return .init(content: [.text(jsonStr(r))])

    case "export_history":
        let format = args["format"]?.stringValue ?? "json"
        if format == "csv" {
            let csv = try await client.getText("/history/export/csv")
            return .init(content: [.text(csv)])
        }
        let r = try await client.get("/history/export/json")
        return .init(content: [.text(jsonStr(r))])

    case "get_ocr_languages":
        let r = try await client.get("/ocr/languages")
        return .init(content: [.text(jsonStr(r))])

    case "set_ocr_languages":
        let langs = args["languages"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let r = try await client.put("/ocr/languages", body: ["languages": langs])
        return .init(content: [.text(jsonStr(r))])

    default:
        return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
    }
}

// MARK: - Helpers

private func str(_ val: Value?) -> String { val?.stringValue ?? "" }

private func jsonStr(_ dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
          let s = String(data: data, encoding: .utf8)
    else { return "\(dict)" }
    return s
}

extension Value {
    var stringValue: String? { if case .string(let s) = self { return s }; return nil }
    var intValue: Int? { if case .int(let i) = self { return i }; return nil }
    var doubleValue: Double? {
        if case .double(let d) = self { return d }
        if case .int(let i) = self { return Double(i) }
        return nil
    }
    var boolValue: Bool? { if case .bool(let b) = self { return b }; return nil }
    var arrayValue: [Value]? { if case .array(let a) = self { return a }; return nil }
}
