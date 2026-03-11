import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var meditationVM: MeditationLibraryViewModel
    @EnvironmentObject var userProgressVM: UserProgressViewModel
    @EnvironmentObject var challengesVM: ChallengesViewModel
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Profil").fontWeight(.semibold)
                        }
                        .foregroundColor(Color(hex: "#6BA59B"))
                    }
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                ActiveChallengeCard(
                    display: challengesVM.activeChallenge,
                    resetAction: { Task { await challengesVM.resetActiveChallenge() } },
                    selectedTab: $selectedTab
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(challengesVM.availableChallenges) { display in
                            AvailableChallengeCard(
                                display: display,
                                activeChallenge: $challengesVM.activeChallenge,
                                startAction: {
                                    Task {
                                        if challengesVM.activeChallenge != nil {
                                            await challengesVM.resetActiveChallenge()
                                        }
                                        challengesVM.startChallenge(display)
                                    }
                                }
                            )
                        }
                        
                        ForEach(challengesVM.completedChallenges) { display in
                            AvailableChallengeCard(
                                display: display,
                                activeChallenge: $challengesVM.activeChallenge,
                                startAction: {}
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            challengesVM.userProgressVM = userProgressVM
            challengesVM.updateUserLevel(userProgressVM.level)
            Task { await challengesVM.loadAll() }
        }
        .onChange(of: userProgressVM.level) { _ in
            challengesVM.updateUserLevel(userProgressVM.level)
        }
        .navigationBarHidden(true)
    }
}
