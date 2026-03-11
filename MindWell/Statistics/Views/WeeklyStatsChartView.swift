import SwiftUI

struct WeeklyStatsChartView: View {
    @EnvironmentObject var moodVM: MoodViewModel
    
    private let moodOrder = ["angry", "sad", "neutral", "happy", "joy"]
    
    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            Text("Statystyki tygodniowe")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            Text(currentWeekRange())
                .font(.caption)
                .foregroundColor(.gray)
            
            if !weeklyStats().isEmpty {
                
                let stats = weeklyStats()
                
                let maxValue = max(stats.map { $0.count }.max() ?? 1, 1)
                let maxBarHeight: CGFloat = 150
                
                HStack(alignment: .bottom, spacing: 22) {
                    ForEach(moodOrder, id: \.self) { mood in
                        
                        let stat = stats.first(where: { $0.mood == mood })
                        let count = stat?.count ?? 0
                        
                        let barHeight = CGFloat(count) / CGFloat(maxValue) * maxBarHeight
                        
                        VStack(spacing: 8) {
                            
                            Rectangle()
                                .fill(Color(hex: stat?.color ?? "#EAEAEA"))
                                .frame(width: 40, height: barHeight == 0 ? 8 : barHeight)
                                .cornerRadius(12)
                                .shadow(radius: 3)
                            
                            Text("\(count) \(count == 1 ? "dzień" : "dni")")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            let moodName = stat?.mood ?? mood
                            if let imageName = imageForMood(moodName) {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                            }
                            
                        }
                    }
                }
                .frame(height: maxBarHeight + 70)
                .frame(maxWidth: .infinity)
            }
            else {
                Text("Brak danych o nastroju w tym tygodniu")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 30)
            }
        }
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.25), radius: 5, x: 0, y: 3)
        .padding(.horizontal, 16)
    }
    
    private func currentWeekRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        let calendar = Calendar.current
        let now = Date()
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)
        else { return "" }
        return "(\(formatter.string(from: startOfWeek))–\(formatter.string(from: endOfWeek)))"
    }
    
    private func imageForMood(_ mood: String) -> String? {
        switch mood {
        case "angry": return "angry"
        case "sad": return "sad"
        case "neutral": return "neutral"
        case "happy": return "happy"
        case "joy": return "joy"
        default: return nil
        }
    }
    
    private func weeklyStats() -> [MoodStat] {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        
        let iso1 = ISO8601DateFormatter()
        iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        
        var weeklyMoods: [MoodEntry] = []
        
        for entry in moodVM.savedMoods {
            var parsedDate: Date? = nil
            
            if let d = iso1.date(from: entry.date) {
                parsedDate = d
            } else if let d = iso2.date(from: entry.date) {
                parsedDate = d
            } else if let d = df.date(from: entry.date) {
                parsedDate = d
            }
            
            if let d = parsedDate, d >= startOfWeek {
                weeklyMoods.append(entry)
            }
        }
        
        let grouped = Dictionary(grouping: weeklyMoods, by: { $0.mood })
        return grouped.map { mood, entries in
            MoodStat(mood: mood, count: entries.count, color: moodVM.hexColor(for: mood))
        }
    }
}
