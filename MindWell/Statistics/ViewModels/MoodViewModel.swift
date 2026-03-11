import Foundation
import Combine

@MainActor
final class MoodViewModel: ObservableObject {
    @Published var savedMoods: [MoodEntry] = []
    @Published var moodStats: [MoodStat] = []
    @Published var todayMood: String? = nil
    @Published var isLoading = false
    
    weak var userprogressVM: UserProgressViewModel?
    
    private let shortDateFormatter = DateFormatter()
    private let moodOrder = ["angry", "sad", "neutral", "happy", "joy"]
    
    init() {
        shortDateFormatter.dateFormat = "yyyy-MM-dd"
        shortDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        Task {
            await fetchMoods()
        }
    }
    
    func loadSavedMoods() async {
        await fetchMoods()
    }
    
    func saveMood(_ mood: String) async {
        isLoading = true
        defer { isLoading = false }
        
        let today = shortDateFormatter.string(from: Date())
        let body = ["mood": mood, "date": today]
        
        do {
            let bodyDict: [String: String] = ["mood": mood, "date": today]
            try await NetworkManager.shared.post(EmptyResponse.self, to: "/moods", body: body)
            todayMood = mood
            await fetchMoods()
            
            NotificationCenter.default.post(name: .pointsUpdated, object: nil)
            await userprogressVM?.loadProgress()
            
        } catch {
            print("Error saving the mood: \(error)")
        }
    }
    
    func fetchMoods() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let moods: [MoodEntry] = try await NetworkManager.shared.get([MoodEntry].self, from: "/moods")
            savedMoods = moods.sorted { $0.date < $1.date }
            updateTodayMood()
            updateStats()
        } catch {
            print("Error loading moods: \(error)")
            savedMoods = []
            moodStats = []
            todayMood = nil
        }
    }
    
    private func updateTodayMood() {
        let todayStr = shortDateFormatter.string(from: Date())
        todayMood = savedMoods.last(where: { $0.date.hasPrefix(todayStr) })?.mood
    }
    
    private func updateStats() {
        let grouped = Dictionary(grouping: savedMoods, by: { $0.mood })
        
        moodStats = grouped.map { mood, entries in
            MoodStat(mood: mood, count: entries.count, color: hexColor(for: mood))
        }
        .sorted { moodOrder.firstIndex(of: $0.mood) ?? 99 < moodOrder.firstIndex(of: $1.mood) ?? 99 }
    }
    
    func hexColor(for mood: String) -> String {
        switch mood.lowercased() {
        case "angry":   return "#E27D60"
        case "sad":     return "#9EBEF0"
        case "neutral": return "#F6B6B6"
        case "happy":   return "#9CCDB4"
        case "joy":     return "#F9E49B"
        default:        return "#CCCCCC"
        }
    }
}

struct EmptyResponse: Decodable {}
