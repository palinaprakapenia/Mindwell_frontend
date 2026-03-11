import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var authVM: UserAuthViewModel
    @EnvironmentObject var userProgressVM: UserProgressViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F4EEE9").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("MindWell")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "7DBAA9"))
                        
                        Text("Zaloguj się")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                        
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                            
                            SecureField("Hasło", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 30)
                        
                        if let error = authVM.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            authVM.login(
                                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                                password: password,
                                userProgressVM: userProgressVM
                            )
                        } label: {
                            Text("Zaloguj się")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "7DBAA9"))
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 30)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                                Text("Nie masz konta?")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: true, vertical: false)
                                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                            }
                            
                            NavigationLink(destination: RegisterView().environmentObject(authVM)) {
                                Text("Zarejestruj się")
                                    .font(.title3.bold())
                                    .foregroundColor(Color(hex: "7DBAA9"))
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.2), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
