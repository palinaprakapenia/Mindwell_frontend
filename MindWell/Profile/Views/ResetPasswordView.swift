import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: UserAuthViewModel
    
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSaving: Bool = false
    @State private var saveMessage: String?
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    VStack(spacing: 20) {
                        passwordField(label: "Stare hasło", text: $oldPassword)
                        passwordField(label: "Nowe hasło", text: $newPassword)
                        passwordField(label: "Potwierdź nowe hasło", text: $confirmPassword)
                    }
                    .padding(.horizontal, 30)
                    
                    HStack(spacing: 20) {
                        Button("Wróć") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        
                        Button {
                            Task { await updatePassword() }
                        } label: {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Zmień hasło").fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSaving ? Color.gray.opacity(0.6) : Color(hex: "#6BA59B"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, 30)
                    
                    if let message = saveMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                }
                .padding(.vertical, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private func passwordField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SecureField("", text: text)
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
    
    private func updatePassword() async {
        guard !oldPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            saveMessage = "Wszystkie pola są wymagane"
            return
        }
        guard newPassword == confirmPassword else {
            saveMessage = "Nowe hasła nie pasują"
            return
        }
        
        isSaving = true
        saveMessage = nil
        
        struct PasswordUpdateRequest: Encodable {
            let oldPassword: String
            let newPassword: String
        }
        
        let requestBody = PasswordUpdateRequest(oldPassword: oldPassword, newPassword: newPassword)
        
        do {
            let response: [String: String] = try await NetworkManager.shared.put(
                [String: String].self,
                to: "/user/reset-password",
                body: requestBody
            )
            
            await MainActor.run {
                isSaving = false
                saveMessage = response["message"] ?? "Hasło zostało zmienione"
                if response["message"] == "Hasło zostało zmienione" {
                    oldPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
            }
        } catch {
            await MainActor.run {
                isSaving = false
                saveMessage = "Błąd: \(error.localizedDescription)"
            }
        }
    }
}
