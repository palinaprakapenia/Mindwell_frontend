import SwiftUI

@main
struct MindWellApp: App {
    let persistence = PersistenceController.shared
    
    let meditationVM = MeditationLibraryViewModel()
    let moodVM = MoodViewModel()
    let authVM = UserAuthViewModel()
    let dailytaskVM = DailyTaskViewModel()
    let userprogressVM = UserProgressViewModel()
    let challengesVM = ChallengesViewModel()
    let achievementVM = AchievementViewModel()
    
    init() {
        userprogressVM.achievementVM = achievementVM
        moodVM.userprogressVM = userprogressVM
        achievementVM.userProgressVM = userprogressVM 
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(meditationVM)
                .environmentObject(moodVM)
                .environmentObject(authVM)
                .environmentObject(dailytaskVM)
                .environmentObject(userprogressVM)
                .environmentObject(challengesVM)
                .environmentObject(achievementVM)
        }
    }
}
