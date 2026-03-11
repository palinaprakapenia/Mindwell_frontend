import SwiftUI

struct MeditationCard: View {
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    @EnvironmentObject private var userprogressVM: UserProgressViewModel
    
    let meditationId: String
    var animation: Namespace.ID
    var isFavouriteView: Bool = false
    var isHistoryView: Bool = false
    var onDelete: (() -> Void)?
    
    @State private var showPurchaseAlert = false
    @State private var isProcessing = false
    
    private var meditation: MeditationWithFavorite? {
        meditationVM.allMeditations.first { $0.id == meditationId }
    }
    
    private var isLocked: Bool {
        guard let med = meditation else { return true }
        return med.price > 0
    }
    
    private var isUnlocked: Bool {
        guard let med = meditation else { return false }
        return !isLocked || med.isUnlocked
    }
    
    var body: some View {
        if let meditation = meditation {
            HStack(spacing: 15) {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(hex: "#6BA59B"))
                    .opacity(isLocked && !isUnlocked ? 0.5 : 1.0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meditation.title)
                        .font(.headline)
                        .foregroundColor(isFavouriteView ? Color(hex: "#6BA59B") : .primary)
                        .opacity(isLocked && !isUnlocked ? 0.7 : 1.0)
                    
                    Text("\(meditation.category) • \(meditation.duration) • \(meditation.difficulty)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isHistoryView {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                } else {
                    Group {
                        if isLocked && !isUnlocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 22))
                        } else {
                            Button {
                                Task { await meditationVM.toggleFavorite(meditation.meditation) }
                            } label: {
                                Image(systemName: meditation.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(Color(hex: "#EA8864"))
                                    .font(.system(size: 26))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 10)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            .opacity(isProcessing ? 0.7 : 1.0)
            .onTapGesture {
                if isUnlocked {
                    meditationVM.goToDetail(id: meditation.id, fromFavourites: isFavouriteView, fromHistory: isHistoryView )
                } else {
                    showPurchaseAlert = true
                }
            }
            .alert("Kup medytację", isPresented: $showPurchaseAlert) {
                Button("Anuluj", role: .cancel) { }
                Button("Kup za \(Int(meditation.price)) pkt") {
                    Task {
                        isProcessing = true
                        defer { isProcessing = false }
                        
                        let success = await purchaseMeditation(meditation.meditation)
                        if success {
                            await meditationVM.fetchMeditations()
                            await userprogressVM.loadProgress()
                            NotificationCenter.default.post(name: .pointsUpdated, object: nil)
                        }
                    }
                }
            } message: {
                Text("Czy chcesz odblokować tę medytację?\nKoszt: \(Int(meditation.price)) pkt")
            }
        } else {
            EmptyView()
        }
    }
    
    private func purchaseMeditation(_ meditation: Meditation) async -> Bool {
        do {
            let response: PurchaseResponse = try await NetworkManager.shared.post(
                PurchaseResponse.self,
                to: "/purchases/\(meditation.id)",
                body: EmptyBody()
            )
            return response.success
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
}

struct PurchaseResponse: Decodable {
    let success: Bool
    let alreadyOwned: Bool?
    let alreadyFree: Bool?
}
