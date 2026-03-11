import Foundation

enum API {
#if targetEnvironment(simulator)
    static let baseURL = "http://127.0.0.1:3000/api"
#else
    static let baseURL = "http://192.168.1.163:3000/api"
#endif
}
