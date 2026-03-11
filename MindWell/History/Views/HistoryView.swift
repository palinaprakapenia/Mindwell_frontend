import SwiftUI
import CoreData

struct HistoryView: View {
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "watchedAt", ascending: false)],
        animation: .default
    )
    private var watchedMeditations: FetchedResults<WatchedMeditation>
    
    @Namespace private var animation
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "d MMMM"
        return f
    }()
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "HH:mm"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    backButton
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal)
                
                HStack {
                    Text("Historia")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal)
            }
            .background(Color(hex: "#F8F3ED"))
            
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: []) {
                    if watchedMeditations.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        ForEach(groupedByDay, id: \.0) { (day, items) in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(sectionTitle(for: day))
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                ForEach(items, id: \.objectID) { watched in
                                    historyRow(for: watched)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(hex: "#F8F3ED"))
        }
        .background(Color(hex: "#F8F3ED").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            Task { await meditationVM.fetchMeditations() }
        }
    }
    
    private var backButton: some View {
        Button {
            meditationVM.goBack()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                Text("Główna")
                    .fontWeight(.semibold)
            }
            .foregroundColor(Color(hex: "#6BA59B"))
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("Brak historii")
                .font(.title2.bold())
            
            Text("Twoje odsłuchane medytacje pojawią się tutaj")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private func historyRow(for watched: WatchedMeditation) -> some View {
        MeditationCard(
            meditationId: watched.id ?? "",
            animation: animation,
            isFavouriteView: false,
            isHistoryView: true,
            onDelete: {
                withAnimation(.easeOut(duration: 0.38)) {
                    context.delete(watched)
                    try? context.save()
                }
            }
        )
        .overlay(alignment: .topTrailing) {
            Text(timeFormatter.string(from: watched.watchedAt ?? Date()))
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .padding(8)
        }
        .onTapGesture {
            meditationVM.goToDetail(
                id: watched.id ?? "",
                fromFavourites: false,
                fromHistory: true
            )
        }
    }
    
    private var groupedByDay: [(Date, [WatchedMeditation])] {
        Dictionary(grouping: watchedMeditations) { item in
            Calendar.current.startOfDay(for: item.watchedAt ?? Date())
        }
        .sorted { $0.key > $1.key }
        .map { ($0.key, $0.value) }
    }
    
    private func sectionTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Dzisiaj"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Wczoraj"
        } else {
            return dateFormatter.string(from: date)
        }
    }
}
