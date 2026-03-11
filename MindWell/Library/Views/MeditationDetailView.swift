import SwiftUI

struct MeditationDetailView: View {
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    @EnvironmentObject private var dailytaskVM: DailyTaskViewModel
    @EnvironmentObject private var userProgressVM: UserProgressViewModel
    @EnvironmentObject private var challengesVM: ChallengesViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    let meditationId: String
    let backTitle: String
    
    @Environment(\.dismiss) private var dismiss
    
    private var meditation: MeditationWithFavorite? {
        meditationVM.allMeditations.first { $0.id == meditationId }
    }
    
    private var fromFavourites: Bool { backTitle == "Ulubione" }
    private var fromHistory: Bool { backTitle == "Historia" }
    
    var body: some View {
        ZStack {
            Color(hex: "#F8F3ED").ignoresSafeArea()
            
            if let meditation = meditation {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if let url = URL(string: meditation.videoUrl) {
                            YouTubePlayer(url: url, meditation: meditation)
                                .frame(height: 260)
                                .cornerRadius(16)
                                .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(meditation.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .lineLimit(2)
                                
                                Spacer()
                                
                                Button {
                                    Task { await meditationVM.toggleFavorite(meditation.meditation) }
                                } label: {
                                    Image(systemName: meditation.isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(hex: "#EA8864"))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("\(meditation.category) • \(meditation.duration) • \(meditation.difficulty)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let description = meditation.description {
                                Text(description)
                                    .font(.body)
                                    .lineSpacing(6)
                            }
                            
                            if let credit = meditation.credit {
                                Text("Credit: \(credit)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 10)
                }
            } else {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    meditationVM.goBack()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(backTitle)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color(hex: "#6BA59B"))
                }
            }
        }
        .onDisappear {
            meditationVM.pendingDailyTaskUserId = ""
            Task { await dailytaskVM.loadDailyTask() }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                guard let meditation = meditation else { return }
                
                Task {
                    HistoryManager.save(meditation: meditation, context: viewContext)
                }
            }
        }
    }
}
