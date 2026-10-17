import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A non-2xx answer from FreezeText's local API.
///
/// Before 0.2.0 the client ignored the HTTP status: a wrong token came back as
/// a normal tool result. Now every refusal becomes an MCP error with a
/// sentence the agent can act on.
struct FreezeTextAPIError: Error {
    let status: Int
    /// The `error` field of FreezeText's JSON answer.
    let code: String?
    /// The `message` field, or the raw body if it was not JSON.
    let detail: String?

    var message: String {
        switch (status, code) {
        case (401, _):
            return "FreezeText rejected the API token (HTTP 401). Set FREEZETEXT_API_TOKEN to the token "
                + "shown in FreezeText → Settings → API (“API Token”)."
        case (503, "API token not configured"):
            return "FreezeText has no API token yet (HTTP 503). Generate one in FreezeText → Settings → API "
                + "and set FREEZETEXT_API_TOKEN to it."
        default:
            let reason = [code, detail].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ": ")
            return "FreezeText answered HTTP \(status)" + (reason.isEmpty ? "." : ": \(reason)")
        }
    }

    init(status: Int, body: Data) {
        self.status = status
        let json = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        self.code = json?["error"] as? String
        if let json {
            self.detail = json["message"] as? String
        } else {
            let text = String(data: body, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.detail = text.isEmpty ? nil : String(text.prefix(300))
        }
    }
}

/// HTTP client for the FreezeText app's local API server (default port 9876).
/// Configured via environment variables FREEZETEXT_API_PORT and FREEZETEXT_API_TOKEN.
actor FreezeTextClient {
    private let base: URL
    private let token: String?
    let port: String

    init() {
        let port = ProcessInfo.processInfo.environment["FREEZETEXT_API_PORT"] ?? "9876"
        self.port = port
        self.base = URL(string: "http://localhost:\(port)")!
        self.token = ProcessInfo.processInfo.environment["FREEZETEXT_API_TOKEN"]
    }

    /// Shown when nothing listens on the port.
    nonisolated var notReachableMessage: String {
        "FreezeText is not reachable at http://localhost:\(port). Open FreezeText and turn on "
            + "“Enable API Server” in FreezeText → Settings → API."
    }

    /// Resolves "/path?query" against the base URL. `appendingPathComponent`
    /// percent-encodes the "?", so the app saw "/path%3Fquery" and answered 404.
    private func url(_ path: String) -> URL {
        URL(string: path, relativeTo: base)?.absoluteURL ?? base.appendingPathComponent(path)
    }

    private func authedRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        if let token, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    /// Sends the request and throws `FreezeTextAPIError` for every answer outside 2xx.
    private func send(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FreezeTextAPIError(status: http.statusCode, body: data)
        }
        return data
    }

    private func object(_ data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? ["raw": String(data: data, encoding: .utf8) ?? ""]
    }

    func get(_ path: String) async throws -> [String: Any] {
        object(try await send(authedRequest(url(path))))
    }

    func getText(_ path: String) async throws -> String {
        String(data: try await send(authedRequest(url(path))), encoding: .utf8) ?? ""
    }

    func post(_ path: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        var req = authedRequest(url(path))
        req.httpMethod = "POST"
        if !body.isEmpty {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return object(try await send(req))
    }

    func put(_ path: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        var req = authedRequest(url(path))
        req.httpMethod = "PUT"
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return object(try await send(req))
    }

    func delete(_ path: String) async throws -> [String: Any] {
        var req = authedRequest(url(path))
        req.httpMethod = "DELETE"
        return object(try await send(req))
    }
}

/// True when the app is not there at all (nothing listens on the port).
func isUnreachable(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost, .timedOut, .notConnectedToInternet:
        return true
    default:
        return false
    }
}
