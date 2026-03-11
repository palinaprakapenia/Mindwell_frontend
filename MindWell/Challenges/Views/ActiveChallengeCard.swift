import SwiftUI

struct ActiveChallengeCard: View {
    @EnvironmentObject var meditationVM: MeditationLibraryViewModel
    @EnvironmentObject var challengesVM: ChallengesViewModel
    @EnvironmentObject var userProgressVM: UserProgressViewModel
    @Environment(\.dismiss) private var dismiss
    
    let display: ChallengeDisplay?
    let resetAction: (() -> Void)?
    @Binding var selectedTab: Int
    
    private func isTimeCorrect() -> Bool {
        guard let code = display?.task.code else { return true }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch code {
        case "global_morning_10":
            return currentHour >= 5 && currentHour <= 10
        case "global_evening_10":
            return currentHour >= 18 || currentHour < 0
        default:
            return true
        }
    }
    
    private var buttonTitle: String {
        guard let display = display else { return "Wybierz zadanie" }
        
        if display.completedToday {
            return "Wykonano dzisiaj"
        }
        
        if display.task.code == "global_morning_10" || display.task.code == "global_evening_10" {
            if !isTimeCorrect() {
                let requiredTime = display.task.code == "global_morning_10" ? "5:00 - 11:00" : "18:00 - 00:00"
                return "Poza czasem (\(requiredTime))"
            }
        }
        
        return "Kontynuuj"
    }
    
    private var buttonColor: Color {
        if buttonTitle == "Wykonano dzisiaj" || buttonTitle.contains("Poza czasem") {
            return Color(hex: "#A0A0A0").opacity(0.3)
        }
        return Color(hex: "#6BA59B")
    }
    
    private var buttonForeground: Color {
        if buttonTitle == "Wykonano dzisiaj" || buttonTitle.contains("Poza czasem") {
            return Color(hex: "#6BA59B")
        }
        return Color.white
    }
    
    private var isButtonDisabled: Bool {
        if buttonTitle == "Wykonano dzisiaj" {
            return true
        }
        if display?.task.code == "global_morning_10" || display?.task.code == "global_evening_10" {
            return !isTimeCorrect()
        }
        return false
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                if let display = display {
                    Text("Aktywne wyzwanie")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Text(display.task.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#6BA59B"))
                    
                    Text(display.task.description ?? "")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    ProgressView(value: Double(display.progress), total: Double(display.target))
                        .progressViewStyle(.linear)
                        .tint(Color(hex: "#6BA59B"))
                        .frame(height: 8)
                        .padding(.horizontal, 40)
                    
                    Text("\(display.progress)/\(display.target)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button {
                        if display.task.code == "global_morning_10" {
                            meditationVM.searchText = "poranna"
                        } else if display.task.code == "global_evening_10" {
                            meditationVM.searchText = "sen"
                        }
                        
                        meditationVM.selectedCategory = nil
                        meditationVM.selectedDuration = nil
                        meditationVM.selectedDifficulty = nil
                        meditationVM.applyFilters()
                        
                        selectedTab = 1
                        dismiss()
                        
                        Task { await challengesVM.loadAll() }
                        
                    } label: {
                        Text(buttonTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(buttonForeground)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(buttonColor)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 40)
                    .disabled(isButtonDisabled)
                    
                } else {
                    VStack(spacing: 16) {
                        Text("Brak aktualnych wyzwań")
                            .font(.title2.bold())
                            .foregroundColor(.gray.opacity(0.8))
                        Text("Wybierz jedno z dostępnych poniżej")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(display != nil ? Color(hex: "#6BA59B").opacity(0.3) : Color.gray.opacity(0.2))
            )
            
            if let display = display {
                Button {
                    Task {
                        await challengesVM.resetActiveChallenge()
                        await challengesVM.loadAll()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#6BA59B"))
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
        }
        .id(challengesVM.activeChallenge?.id ?? "no-challenge")
    }
}
