import SwiftUI

struct StatsChartView: View {
    @EnvironmentObject var moodVM: MoodViewModel
    
    private let moodOrder = ["angry", "sad", "neutral", "happy", "joy"]
    private let maxBarHeight: CGFloat = 150
    
    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            
            Text("Statystyki ogólne")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            Text("Emocje z całego okresu korzystania z aplikacji")
                .font(.caption)
                .foregroundColor(.gray)
            
            if !moodVM.moodStats.isEmpty {
                
                let maxValue = max(moodVM.moodStats.map { $0.count }.max() ?? 1, 1)
                
                HStack(alignment: .bottom, spacing: 22) {
                    ForEach(moodOrder, id: \.self) { mood in
                        let stat = moodVM.moodStats.first(where: { $0.mood == mood })
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
                            
                            if let moodName = stat?.mood, let imageName = imageForMood(moodName) {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                            } else if let imageName = imageForMood(mood) {
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
                
            } else {
                Text("Brak danych o nastroju")
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
}
