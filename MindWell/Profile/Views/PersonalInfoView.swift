import SwiftUI

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: UserAuthViewModel
    
    @State private var username: String
    @State private var email: String
    @State private var birthdate: Date
    @State private var selectedImage: Image? = nil
    @State private var uiImage: UIImage? = nil
    @State private var downloadedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var saveMessage: String?
    
    var user: User
    var onSave: (() -> Void)?
    
    init(user: User, onSave: (() -> Void)? = nil) {
        self.user = user
        self.onSave = onSave
        
        let dateString = user.birthDate ?? ""
        let formatter = DateFormatter.yyyyMMdd
        formatter.timeZone = TimeZone.current
        
        let date = formatter.date(from: dateString) ?? Date()
        
        _username = State(initialValue: user.name)
        _email = State(initialValue: user.email)
        _birthdate = State(initialValue: date)
    }
    
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    Button {
                        showImagePicker = true
                    } label: {
                        if let selectedImage = selectedImage {
                            selectedImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 8)
                        } else if let uiImage = uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 8)
                        } else if let downloadedImage = downloadedImage {
                            Image(uiImage: downloadedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 8)
                        } else {
                            avatarPlaceholder
                                .frame(width: 130, height: 130)
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 8)
                                .task {
                                    if let avatarURL = user.avatarURL, !avatarURL.isEmpty {
                                        let fullAvatarURL = avatarURL.hasPrefix("http") ? avatarURL : "\(API.baseURL)\(avatarURL)"
                                        if let url = URL(string: fullAvatarURL) {
                                            do {
                                                let (data, _) = try await URLSession.shared.data(from: url)
                                                if let uiImage = UIImage(data: data) {
                                                    await MainActor.run {
                                                        self.downloadedImage = uiImage
                                                    }
                                                }
                                            } catch {
                                                print("Error loading avatar: \(error)")
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(selectedImage: $selectedImage, uiImage: $uiImage)
                    }
                    
                    VStack(spacing: 20) {
                        infoField(label: "Username", text: $username)
                        infoField(label: "Email", text: $email)
                        dateField(label: "Data urodzenia", date: $birthdate)
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
                            Task { await updateUserProfile() }
                        } label: {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Zapisz").fontWeight(.semibold)
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
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color(hex: "#CDE3DD"))
            .overlay(
                Text(user.initials)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }
    
    private func updateUserProfile() async {
        isSaving = true
        saveMessage = nil
        
        struct UpdateRequest: Encodable {
            let name: String
            let email: String
            let birthDate: String
        }
        
        let requestBody = UpdateRequest(
            name: username,
            email: email,
            birthDate: DateFormatter.yyyyMMdd.string(from: birthdate)
        )
        
        do {
            try await NetworkManager.shared.put(
                EmptyResponse.self,
                to: "/user/profile",
                body: requestBody
            )
            
            if let image = uiImage {
                await uploadAvatar(image: image)
            }
            
            await MainActor.run {
                isSaving = false
                saveMessage = "Dane zostały zapisane"
                onSave?()
                Task { await authVM.loadCurrentUser() }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
            
        } catch {
            await MainActor.run {
                isSaving = false
                saveMessage = "Błąd: \(error.localizedDescription)"
            }
        }
    }
    
    private func uploadAvatar(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: URL(string: "\(API.baseURL)/user/avatar")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = KeychainHelper.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let _ = try await URLSession.shared.upload(for: request, from: body)
            await authVM.loadCurrentUser()
        } catch {
            print("Upload error: \(error)")
        }
    }
    
    private func infoField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("", text: text)
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
    
    private func dateField(label: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            DatePicker("", selection: date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 3)
                .overlay(alignment: .trailing) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
