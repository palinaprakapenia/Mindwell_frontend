import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var achievementVM: AchievementViewModel
    @EnvironmentObject var userProgressVM: UserProgressViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAchievement: AchievementDisplay? = nil
    
    private var unlockedCount: Int {
        achievementVM.allAchievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                navigationHeader
                
                if achievementVM.isLoading {
                    ProgressView().padding(.top, 50)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            
                            progressHeader
                            
                            if !achievementVM.allAchievements.filter({ $0.isUnlocked }).isEmpty {
                                AchievementSection(
                                    title: "Zdobyte odznaki",
                                    achievements: achievementVM.allAchievements.filter { $0.isUnlocked }.sorted { $0.achievement.pointsReward > $1.achievement.pointsReward },
                                    selectedAchievement: $selectedAchievement
                                )
                            }
                            
                            if !achievementVM.allAchievements.filter({ !$0.isUnlocked }).isEmpty {
                                AchievementSection(
                                    title: "Do odblokowania",
                                    achievements: achievementVM.allAchievements.filter { !$0.isUnlocked }.sorted { $0.achievement.conditionValue < $1.achievement.conditionValue },
                                    selectedAchievement: $selectedAchievement
                                )
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 15)
                    }
                }
            }
            .onAppear {
                Task { await userProgressVM.loadProgress() }
            }
            .task {
                if achievementVM.allAchievements.isEmpty {
                    await achievementVM.loadAchievements()
                }
            }
            .onChange(of: userProgressVM.userProgress) { progress in
                if progress != nil {
                    Task { await achievementVM.loadAchievements() }
                }
            }
            .navigationBarHidden(true)
            
            .sheet(item: $selectedAchievement) { display in
                AchievementDetailSheet(display: display)
            }
        }
    }
    
    private var navigationHeader: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Profil").fontWeight(.semibold)
                }
                .foregroundColor(Color(hex: "#6BA59B"))
            }
            Spacer()
            Button("Profil") {}.hidden()
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var progressHeader: some View {
        VStack {
            Text("Twoje osiągnięcia")
                .font(.title3.bold())
            Text("Odblokowano: \(unlockedCount) z \(achievementVM.allAchievements.count)")
                .foregroundColor(Color(hex: "#6BA59B"))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "#E8F0EE"))
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
}

struct AchievementSection: View {
    let title: String
    let achievements: [AchievementDisplay]
    @Binding var selectedAchievement: AchievementDisplay?
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.title2.bold())
                .padding(.horizontal, 15)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(achievements) { display in
                    AchievementItemView(display: display, selectedAchievement: $selectedAchievement)
                }
            }
            .padding(.horizontal, 10)
        }
    }
}
struct AchievementItemView: View {
    let display: AchievementDisplay
    @Binding var selectedAchievement: AchievementDisplay?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(display.isUnlocked ? Color(hex: "#CDE3DD") : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: display.achievement.icon ?? "trophy.fill")
                    .font(.title2)
                    .foregroundColor(display.isUnlocked ? Color(hex: "#6BA59B") : .gray.opacity(0.6))
            }
            
            Text(display.achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.black)
            
            if !display.isUnlocked {
                Text(display.progressText)
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#6BA59B"))
            }
        }
        .frame(maxWidth: 80)
        .onTapGesture {
            selectedAchievement = display
        }
    }
}

struct AchievementDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let display: AchievementDisplay
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 10)
            
            ZStack {
                Circle()
                    .fill(display.isUnlocked ? Color(hex: "#CDE3DD") : Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: display.achievement.icon ?? "trophy.fill")
                    .font(.largeTitle)
                    .foregroundColor(display.isUnlocked ? Color(hex: "#6BA59B") : .gray)
            }
            
            Text(display.achievement.title)
                .font(.title2.bold())
            
            Text(display.achievement.description ?? "Brak szczegółowego opisu.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            VStack(spacing: 5) {
                if display.isUnlocked {
                    Text("STATUS: Osiągnięto ")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#6BA59B"))
                } else {
                    Text("POSTĘP:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(display.progressText)
                        .font(.title3.bold())
                        .foregroundColor(Color(hex: "#6BA59B"))
                }
                
                Text("Nagroda: \(display.achievement.pointsReward) pkt + \(display.achievement.xpReward) XP")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
            
            Spacer()
            
            Button("Zamknij") {
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#6BA59B"))
            .foregroundColor(.white)
            .cornerRadius(15)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "#F8F3ED").ignoresSafeArea())
    }
}
