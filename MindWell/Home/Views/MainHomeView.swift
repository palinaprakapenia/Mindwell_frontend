import SwiftUI
import Foundation

struct MainHomeView: View {
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    @EnvironmentObject private var moodVM: MoodViewModel
    @EnvironmentObject private var dailytaskVM: DailyTaskViewModel
    @EnvironmentObject private var userprogressVM: UserProgressViewModel
    @EnvironmentObject private var challengesVM: ChallengesViewModel
    
    @Binding var selectedTab: Int
    
    private func isTimeCorrect(for challengeCode: String) -> Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch challengeCode {
        case "global_morning_10":
            return currentHour >= 5 && currentHour <= 10
        case "global_evening_10":
            return currentHour >= 18 || currentHour < 0
        default:
            return true
        }
    }
    
    var completedSteps: Int {
        var steps = 0
        if moodVM.todayMood != nil { steps += 1 }
        if dailytaskVM.dailyTaskCompleted { steps += 1 }
        
        if let active = challengesVM.activeChallenge {
            let isTimeRestricted = active.task.code == "global_morning_10" || active.task.code == "global_evening_10"
            if !isTimeRestricted || isTimeCorrect(for: active.task.code) {
                if active.completedToday { steps += 1 }
            }
        }
        return steps
    }
    
    var totalSteps: Int {
        var total = 2
        if challengesVM.activeChallenge != nil { total += 1 }
        return total
    }
    
    var progressFraction: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(completedSteps) / CGFloat(totalSteps)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack {
                        HStack(spacing: 15) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(Color(hex: "#EA8864"))
                                .font(.system(size: 24))
                                .onTapGesture { meditationVM.goToFavourites() }
                            
                            Image(systemName: "clock")
                                .font(.system(size: 24))
                                .onTapGesture { meditationVM.goToHistory() }
                        }
                        Spacer()
                        
                        Text("\(userprogressVM.points) pkt")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#6BA59B"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#6BA59B").opacity(0.15))
                                    .overlay(Capsule().stroke(Color(hex: "#6BA59B"), lineWidth: 2))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    HStack {
                        Text("Rozpocznij dzień")
                            .font(.title3.bold())
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    
                    HStack(alignment: .top, spacing: 16) {
                        ProgressLineSide(
                            progressFraction: progressFraction,
                            hasDailyTask: dailytaskVM.dailyTask != nil || dailytaskVM.dailyTaskCompleted,
                            hasChallenge: challengesVM.activeChallenge != nil
                        )
                        .padding(.top, 50)
                        
                        VStack(spacing: 20) {
                            VStack(spacing: 20) {
                                Text("Jak się dziś czujesz?")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#6BA59B"))
                                
                                HStack(spacing: 0) {
                                    if let todayMood = moodVM.todayMood {
                                        Spacer()
                                        Image(todayMood)
                                            .resizable()
                                            .frame(width: 95, height: 95)
                                            .clipShape(Circle())
                                        Spacer()
                                    } else {
                                        ForEach(["angry", "sad", "neutral", "happy", "joy"], id: \.self) { mood in
                                            Button {
                                                Task {
                                                    await moodVM.saveMood(mood)
                                                    await userprogressVM.loadProgress()
                                                }
                                            } label: {
                                                Image(mood)
                                                    .resizable()
                                                    .frame(width: 65, height: 65)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                }
                                .animation(.easeInOut, value: moodVM.todayMood)
                                
                                if moodVM.todayMood != nil {
                                    Button("Zmień nastrój") {
                                        withAnimation { moodVM.todayMood = nil }
                                    }
                                    .font(.footnote)
                                    .foregroundColor(Color(hex: "#6BA59B"))
                                }
                            }
                            .padding(.vertical, 25)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                            
                            if dailytaskVM.dailyTask?.type == "daily" || dailytaskVM.dailyTaskCompleted {
                                VStack(spacing: 12) {
                                    Text("Dzisiejsze zadanie")
                                        .font(.headline)
                                        .foregroundColor(.gray.opacity(0.8))
                                    
                                    if let task = dailytaskVM.dailyTask ?? (dailytaskVM.dailyTaskCompleted ? dailytaskVM.dailyTask : nil) {
                                        Text(task.title)
                                            .font(.title3.bold())
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        if dailytaskVM.dailyTaskCompleted {
                                            Text("+30 pkt • +50 XP")
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "#6BA59B"))
                                        }
                                        
                                        Button {
                                            guard let meditationId = dailytaskVM.dailyTask?.targetMeditationId else {
                                                print("Check Mongo")
                                                return
                                            }
                                            
                                            meditationVM.pendingDailyTaskUserId = dailytaskVM.userTaskId
                                            
                                            meditationVM.goToDetail(
                                                id: meditationId,
                                                fromFavourites: false,
                                                fromHistory: false,
                                                fromDailyTask: true
                                            )
                                        } label: {
                                            Text(dailytaskVM.dailyTaskCompleted ? "Wykonane" : "Rozpocznij")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 50)
                                                .background(
                                                    Capsule()
                                                        .fill(dailytaskVM.dailyTaskCompleted ? Color.gray.opacity(0.6) : Color(hex: "#6BA59B"))
                                                )
                                        }
                                        .disabled(dailytaskVM.dailyTaskCompleted)
                                    }
                                }
                                .padding(24)
                                .background(Color.white)
                                .cornerRadius(22)
                                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                            }
                            
                            if let activeGlobal = challengesVM.activeChallenge {
                                
                                let isTimeRestricted = activeGlobal.task.code == "global_morning_10" || activeGlobal.task.code == "global_evening_10"
                                let isTimeCorrect = isTimeRestricted ? self.isTimeCorrect(for: activeGlobal.task.code) : true
                                
                                let isCompletedToday = activeGlobal.completedToday
                                
                                let buttonTitle: String = {
                                    if isCompletedToday {
                                        return "Wykonano dzisiaj"
                                    } else if isTimeRestricted && !isTimeCorrect {
                                        let requiredTime = activeGlobal.task.code == "global_morning_10" ? "5:00 - 11:00" : "18:00 - 00:00"
                                        return "Poza czasem (\(requiredTime))"
                                    } else {
                                        return "Kontynuuj"
                                    }
                                }()
                                
                                let buttonDisabled = isCompletedToday || (isTimeRestricted && !isTimeCorrect)
                                let buttonColor = buttonDisabled ? Color.gray.opacity(0.6) : Color(hex: "#6BA59B")
                                let buttonForeground = Color.white
                                
                                
                                VStack(spacing: 12) {
                                    Text("Aktywne wyzwanie")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "#6BA59B"))
                                    
                                    Text(activeGlobal.task.title)
                                        .font(.title3.bold())
                                        .multilineTextAlignment(.center)
                                    
                                    ProgressView(value: Double(activeGlobal.progress), total: Double(activeGlobal.target))
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#6BA59B")))
                                        .frame(height: 8)
                                        .padding(.horizontal, 20)
                                    
                                    Text("\(activeGlobal.progress)/\(activeGlobal.target)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Button {
                                        selectedTab = 1
                                        
                                    } label: {
                                        Text(buttonTitle)
                                            .font(Font.system(size: 18, weight: .bold))
                                            .foregroundColor(buttonForeground)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(buttonColor)
                                            .cornerRadius(25)
                                    }
                                    .disabled(buttonDisabled)
                                }
                                .padding(24)
                                .background(Color.white)
                                .cornerRadius(22)
                                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                            }
                            
                        }
                        .padding(.trailing, 30)
                    }
                    .padding(.leading, 30)
                    
                    Spacer(minLength: 120)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pointsUpdated)) { _ in
            Task { await userprogressVM.loadProgress() }
        }
        .onAppear {
            Task {
                await userprogressVM.loadProgress()
                await moodVM.fetchMoods()
                await dailytaskVM.loadDailyTask()
                await challengesVM.loadAll()
            }
        }
    }
}

struct ProgressLineSide: View {
    let progressFraction: CGFloat
    let hasDailyTask: Bool
    let hasChallenge: Bool
    
    private var targetHeight: CGFloat {
        var height: CGFloat = 0
        
        height += 180
        
        if hasDailyTask {
            height += 30
        }
        
        if hasChallenge {
            height += 230
        }
        
        height += 60
        
        return height
    }
    
    var body: some View {
        GeometryReader { geo in
            let totalHeight = targetHeight
            let filledHeight = totalHeight * progressFraction
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#CDE3DD"))
                    .frame(width: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#6BA59B"))
                    .frame(width: 8, height: filledHeight)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: filledHeight)
            }
        }
        .frame(width: 8, height: targetHeight)
    }
}

extension Notification.Name {
    static let pointsUpdated = Notification.Name("pointsUpdated")
}
