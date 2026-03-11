import Foundation

@MainActor
final class UserAuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isCheckingAuth = true
    @Published var errorMessage: String?
    @Published var user: User?
    
    private let service = "MindWellService"
    private let account = "userToken"
    
    init() { }
    
    func register(name: String, email: String, password: String, birthDate: Date) {
        if name.isEmpty || email.isEmpty || password.isEmpty {
            self.errorMessage = "Wypełnij wszystkie pola"
            return
        }
        
        if !email.contains("@") || !email.contains(".") {
            self.errorMessage = "Niepoprawny format email"
            return
        }
        
        if password.count < 6 {
            self.errorMessage = "Hasło musi mieć min. 6 znaków"
            return
        }

        let body = RegisterRequest(
            name: name,
            email: email,
            password: password,
            birthDate: ISO8601DateFormatter().string(from: birthDate)
        )
        Task { await authRequest(to: "/register", body: body) }
    }

    func login(email: String, password: String, userProgressVM: UserProgressViewModel? = nil) {
        if email.isEmpty || password.isEmpty {
            self.errorMessage = "Wprowadź dane logowania"
            return
        }

        let body = LoginRequest(email: email, password: password)
        
        Task {
            do {
                let response: AuthResponse = try await NetworkManager.shared.post(AuthResponse.self, to: "/auth/login", body: body)
                
                if let tokenData = response.token.data(using: .utf8) {
                    KeychainHelper.shared.save(tokenData, service: service, account: account)
                }
                UserDefaults.standard.set(response.token, forKey: account)
                
                self.user = response.user
                self.isLoggedIn = true
                self.errorMessage = nil
                
                if let progressVM = userProgressVM {
                    await progressVM.loadProgress()
                    await progressVM.achievementVM?.checkAndUnlockAchievements()
                }
            } catch {
                self.errorMessage = "Nieprawidłowy email lub hasło"
            }
        }
    }
    
    func logout() {
        isLoggedIn = false
        user = nil
        errorMessage = nil
        
        UserDefaults.standard.removeObject(forKey: account)
        KeychainHelper.shared.delete(service: service, account: account)
        
        objectWillChange.send()
    }
    
    private func authRequest<T: Encodable>(to endpoint: String, body: T) async {
        do {
            let response: AuthResponse = try await NetworkManager.shared.post(
                AuthResponse.self,
                to: "/auth" + endpoint,
                body: body
            )
            
            if let tokenData = response.token.data(using: .utf8) {
                KeychainHelper.shared.save(tokenData, service: service, account: account)
            }
            UserDefaults.standard.set(response.token, forKey: account)
            
            self.user = response.user
            self.isLoggedIn = true
            self.errorMessage = nil
            
        } catch {
            errorMessage = "Błąd logowania lub rejestracji"
            print("Auth error:", error)
        }
    }
    
    func checkTokenAndLoadUser() {
        isCheckingAuth = true
        
        let keychainData = KeychainHelper.shared.read(service: service, account: account)
        let defaultsToken = UserDefaults.standard.string(forKey: account)
        
        if keychainData != nil || defaultsToken != nil {
            if let data = keychainData,
               let token = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(token, forKey: account)
            }
            Task {
                await loadCurrentUser()
                isCheckingAuth = false
            }
        } else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.isCheckingAuth = false
            }
        }
    }
    
    func loadCurrentUser() async {
        do {
            let user: User = try await NetworkManager.shared.get(User.self, from: "/auth/profile")
            self.user = user
            self.isLoggedIn = true
        } catch {
            print("Failed to load user:", error)
            logout()
        }
    }
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let birthDate: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: User
}
