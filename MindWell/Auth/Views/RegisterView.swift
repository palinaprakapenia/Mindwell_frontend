import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var birthDate = Date()
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    @EnvironmentObject var authVM: UserAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "F4EEE9").ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("MindWell")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "7DBAA9"))
                    
                    Text("Utwórz konto")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.8))
                    
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
                                .overlay(alignment: .trailing) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                        }
                        
                        ZStack {
                            if isPasswordVisible {
                                TextField("Hasło", text: $password)
                            } else {
                                SecureField("Hasło", text: $password)
                            }
                            
                            HStack {
                                Spacer()
                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                        .foregroundColor(.gray.opacity(0.7))
                                        .padding(.trailing, 12)
                                }
                            }
                        }
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
                        authVM.register(
                            name: "\(username)",
                            email: email,
                            password: password,
                            birthDate: birthDate
                        )
                    } label: {
                        Text("Utwórz konto")
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
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("Masz już konto?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        
                        Button("Zaloguj się") {
                            dismiss()
                        }
                        .font(.title3.bold())
                        .foregroundColor(Color(hex: "7DBAA9"))
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
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}
