import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: UserAuthViewModel
    @EnvironmentObject var userprogressVM: UserProgressViewModel
    @EnvironmentObject var challengesVM: ChallengesViewModel
    @EnvironmentObject var achievementVM: AchievementViewModel
    
    @State private var showingChallenges = false
    @State private var showingAchievements = false
    @State private var downloadedImage: UIImage? = nil
    @Binding var selectedTab: Int
    
    private var xpInCurrentLevel: Int {
        let thresholds = [0, 100, 300, 500, 700, 1000]
        var prev = 0
        for threshold in thresholds {
            if userprogressVM.xp < threshold { return userprogressVM.xp - prev }
            prev = threshold
        }
        return (userprogressVM.xp - 1000) % 400
    }
    
    private var xpForCurrentLevel: Int {
        let thresholds = [0, 100, 300, 500, 700, 1000]
        for threshold in thresholds {
            if userprogressVM.xp < threshold { return threshold }
        }
        return 400
    }
    
    private var progressFraction: Double {
        guard xpForCurrentLevel > 0 else { return 0 }
        return Double(xpInCurrentLevel) / Double(xpForCurrentLevel)
    }
    
    private var currentLevel: Int { userprogressVM.level }
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            if let user = authVM.user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        VStack(spacing: 12) {
                            if let avatarURL = user.avatarURL, !avatarURL.isEmpty {
                                let fullAvatarURL = avatarURL.hasPrefix("http") ? avatarURL : "\(API.baseURL)\(avatarURL)"
                                
                                if let url = URL(string: fullAvatarURL) {
                                    if let downloadedImage = downloadedImage {
                                        Image(uiImage: downloadedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                    } else {
                                        avatarPlaceholder(user: user)
                                            .frame(width: 110, height: 110)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                            .task {
                                                do {
                                                    let (data, _) = try await URLSession.shared.data(from: url)
                                                    if let uiImage = UIImage(data: data) {
                                                        await MainActor.run {
                                                            self.downloadedImage = uiImage
                                                        }
                                                    }
                                                } catch { print("Error loading avatar: \(error)") }
                                            }
                                    }
                                } else {
                                    avatarPlaceholder(user: user)
                                        .frame(width: 110, height: 110)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                }
                            } else {
                                avatarPlaceholder(user: user)
                                    .frame(width: 110, height: 110)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            }
                            
                            Text(user.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(user.email)
                                .foregroundColor(Color(hex: "#6BA59B"))
                            
                            VStack(spacing: 8) {
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(hex: "#E8F0EE"))
                                        .frame(height: 26)
                                        .frame(width: 340)
                                    
                                    Capsule()
                                        .fill(Color(hex: "#6BA59B"))
                                        .frame(width: max(8, CGFloat(progressFraction) * 340), height: 26)
                                        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progressFraction)
                                    
                                    HStack {
                                        Spacer()
                                        Text("\(xpInCurrentLevel)/\(xpForCurrentLevel) XP")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.trailing, 24)
                                    }
                                }
                                .frame(maxWidth: 340)
                                
                                Text("Poziom \(currentLevel)")
                                    .font(.title3.bold())
                                    .foregroundColor(Color(hex: "#6BA59B"))
                            }
                            .padding(.top, 6)
                        }
                        
                        VStack(spacing: 14) {
                            Button { showingAchievements = true } label: {
                                profileButton(title: "Odznaki")
                            }
                            .fullScreenCover(isPresented: $showingAchievements) {
                                AchievementsView()
                                    .environmentObject(achievementVM)
                                    .environmentObject(userprogressVM)
                            }
                            
                            Button { showingChallenges = true } label: {
                                profileButton(title: "Wyzwania")
                            }
                            .fullScreenCover(isPresented: $showingChallenges) {
                                ChallengesView(selectedTab: $selectedTab)
                                    .environmentObject(challengesVM)
                                    .environmentObject(userprogressVM)
                            }
                            
                            NavigationLink(destination: PersonalInfoView(user: user, onSave: {
                                Task { await authVM.loadCurrentUser() }
                            })) {
                                profileButton(title: "Edytuj dane osobowe")
                            }
                            
                            NavigationLink(destination: ResetPasswordView()) {
                                profileButton(title: "Zmień hasło")
                            }
                            
                            Button("Wyloguj się") {
                                authVM.logout()
                                UserDefaults.standard.removeObject(forKey: "userToken")
                                KeychainHelper.shared.delete(service: "MindWellService", account: "userToken")
                            }
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#6BA59B"))
                            .cornerRadius(25)
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 15)
                    }
                    .padding(.top, 70)
                    .padding(.bottom, 60)
                }
            } else {
                ProgressView("Ładowanie profilu...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#7DBAA9")))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            Task { await userprogressVM.loadProgress() }
        }
        .task {
            if authVM.user == nil,
               KeychainHelper.shared.read(service: "MindWellService", account: "userToken") != nil {
                await authVM.loadCurrentUser()
            }
        }
    }
    
    private func profileButton(title: String) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color(hex: "#6BA59B").opacity(0.6))
        .cornerRadius(25)
        .frame(maxWidth: .infinity)
    }
    
    private func avatarPlaceholder(user: User) -> some View {
        Circle()
            .fill(Color(hex: "#CDE3DD"))
            .overlay(
                Text(user.initials)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }
}
