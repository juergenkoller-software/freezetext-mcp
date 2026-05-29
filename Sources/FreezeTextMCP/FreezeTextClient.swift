import Foundation

/// HTTP client for the FreezeText app's local API server (default port 9876).
/// Configured via environment variables FREEZETEXT_API_PORT and FREEZETEXT_API_TOKEN.
actor FreezeTextClient {
    private let base: URL
    private let token: String?

    init() {
        let port = ProcessInfo.processInfo.environment["FREEZETEXT_API_PORT"] ?? "9876"
        self.base = URL(string: "http://localhost:\(port)")!
        self.token = ProcessInfo.processInfo.environment["FREEZETEXT_API_TOKEN"]
    }

    private func authedRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        if let token, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    func get(_ path: String) async throws -> [String: Any] {
        let req = authedRequest(base.appendingPathComponent(path))
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? ["raw": String(data: data, encoding: .utf8) ?? ""]
    }

    func getText(_ path: String) async throws -> String {
        let req = authedRequest(base.appendingPathComponent(path))
        let (data, _) = try await URLSession.shared.data(for: req)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func post(_ path: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        var req = authedRequest(base.appendingPathComponent(path))
        req.httpMethod = "POST"
        if !body.isEmpty {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? ["raw": String(data: data, encoding: .utf8) ?? ""]
    }

    func put(_ path: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        var req = authedRequest(base.appendingPathComponent(path))
        req.httpMethod = "PUT"
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? ["raw": String(data: data, encoding: .utf8) ?? ""]
    }

    func delete(_ path: String) async throws -> [String: Any] {
        var req = authedRequest(base.appendingPathComponent(path))
        req.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? ["raw": String(data: data, encoding: .utf8) ?? ""]
    }

    func isAppRunning() async -> Bool {
        do {
            _ = try await get("/settings")
            return true
        } catch {
            return false
        }
    }
}
