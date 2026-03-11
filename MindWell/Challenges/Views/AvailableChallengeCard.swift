import SwiftUI

struct AvailableChallengeCard: View {
    let display: ChallengeDisplay
    @Binding var activeChallenge: ChallengeDisplay?
    let startAction: () -> Void
    
    private var isCurrentActive: Bool { activeChallenge?.id == display.id }
    
    private var actualCompletedToday: Bool {
        isCurrentActive ? (activeChallenge?.completedToday ?? false) : display.completedToday
    }
    
    private var buttonTitle: String {
        
        if display.isCompleted {
            return "Wykonano"
        } else if isCurrentActive {
            return "Aktywne"
        } else if activeChallenge != nil {
            return "Nie wykonano"
        } else {
            return "Start"
        }
    }
    
    private var buttonBackground: Color {
        if buttonTitle == "Aktywne" {
            return Color(hex: "#6BA59B").opacity(0.2)
        } else if buttonTitle == "Wykonano" || buttonTitle == "Nie wykonano" {
            return Color(hex: "#E0E0E0")
        } else {
            return Color(hex: "#6BA59B")
        }
    }
    
    private var buttonForeground: Color {
        if buttonTitle == "Aktywne" {
            return Color(hex: "#6BA59B")
        } else if buttonTitle == "Wykonano" || buttonTitle == "Nie wykonano" {
            return Color.gray
        } else {
            return .white
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(display.task.title)
                    .font(.title3.bold())
                Text(display.task.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                if !display.isUnlocked {
                    Text("Dostępne od poziomu \(display.task.requiredLevel ?? 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !display.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.6))
                    .frame(width: 48, height: 48)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Button(action: {
                    if buttonTitle == "Start" {
                        startAction()
                    }
                }) {
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 140, height: 48)
                        .background(buttonBackground)
                        .foregroundColor(buttonForeground)
                        .cornerRadius(24)
                }
                .disabled(buttonTitle != "Start")
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}
