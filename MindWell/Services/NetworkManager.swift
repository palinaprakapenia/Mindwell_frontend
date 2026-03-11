import Foundation

actor NetworkManager {
    static let shared = NetworkManager()
    private let decoder = JSONDecoder()
    private init() {
        decoder.dateDecodingStrategy = .iso8601
    }
    private var token: String? {
        if let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty {return token}
        if let data = KeychainHelper.shared.read(service: "MindWellService", account: "userToken"),
           let token = String(data: data, encoding: .utf8), !token.isEmpty {return token}
        return nil
    }
    private func request(_ url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")}
        request.httpBody = body
        return request
    }
    func delete(to endpoint: String) async throws {
        guard let url = URL(string: API.baseURL + endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {throw URLError(.badServerResponse)}
    }
    func get<T: Decodable>(_ type: T.Type, from endpoint: String) async throws -> T {
        guard let url = URL(string: API.baseURL + endpoint) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(for: request(url))
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {throw URLError(.userAuthenticationRequired)}
        return try decoder.decode(T.self, from: data)
    }
    func post<T: Decodable, B: Encodable>(_ type: T.Type, to endpoint: String, body: B) async throws -> T {
        guard let url = URL(string: API.baseURL + endpoint) else { throw URLError(.badURL) }
        let jsonData = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request(url, method: "POST", body: jsonData))
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {throw URLError(.userAuthenticationRequired)}
        return try decoder.decode(T.self, from: data)
    }
    func put<T: Decodable>(_ type: T.Type, to endpoint: String, body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: API.baseURL + endpoint) else { throw URLError(.badURL) }
        let jsonData = body != nil ? try JSONEncoder().encode(body!) : nil
        let (data, response) = try await URLSession.shared.data(for: request(url, method: "PUT", body: jsonData))
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {throw URLError(.userAuthenticationRequired)}
        return try decoder.decode(T.self, from: data)
    }
    func postRaw<B: Encodable>(to endpoint: String, body: B) async throws -> (Data, URLResponse) {
        guard let url = URL(string: API.baseURL + endpoint) else { throw URLError(.badURL) }
        let jsonData = try JSONEncoder().encode(body)
        let request = self.request(url, method: "POST", body: jsonData)
        return try await URLSession.shared.data(for: request)
    }
}


