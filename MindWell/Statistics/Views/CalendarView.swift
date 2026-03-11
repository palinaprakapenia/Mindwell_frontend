import SwiftUI

private struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let belongsToDisplayedMonth: Bool
}

struct CalendarView: View {
    @EnvironmentObject var moodVM: MoodViewModel
    @State private var displayedMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#6BA59B"))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthYearString(for: displayedMonth))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#6BA59B"))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            HStack {
                ForEach(["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                ForEach(daysInMonth()) { day in
                    ZStack {
                        if let moodColor = moodColor(for: day.date) {
                            Circle()
                                .fill(moodColor)
                                .frame(width: 38, height: 38)
                                .opacity(day.belongsToDisplayedMonth ? 1.0 : 0.35)
                        }
                        else if calendar.isDateInToday(day.date) {
                            Circle()
                                .fill(Color(hex: "#6BA59B").opacity(0.15))
                                .frame(width: 38, height: 38)
                            Circle()
                                .stroke(Color(hex: "#6BA59B"), lineWidth: 2.5)
                                .frame(width: 38, height: 38)
                        }
                        else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle()
                                        .stroke(Color
                                            .gray
                                            .opacity(day.belongsToDisplayedMonth ? 0.2 : 0.1),
                                                lineWidth: 1)
                                )
                        }
                        
                        Text("\(calendar.component(.day, from: day.date))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                day.belongsToDisplayedMonth ? .primary : .gray.opacity(0.5)
                            )
                    }
                    .animation(.easeInOut(duration: 0.3), value: displayedMonth)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.25), radius: 5)
        .padding(.horizontal, 16)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut) {
                displayedMonth = newMonth
            }
        }
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func daysInMonth() -> [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        let offset = (firstWeekday + 5) % 7
        
        let totalDays = offset + daysInMonth
        let rows = Int(ceil(Double(totalDays) / 7.0))
        let totalCells = rows * 7
        
        var days: [CalendarDay] = []
        var currentDate = calendar.date(byAdding: .day, value: -offset, to: monthInterval.start)!
        
        for _ in 0..<totalCells {
            let belongsToDisplayedMonth = calendar.isDate(currentDate, equalTo: displayedMonth, toGranularity: .month)
            days.append(CalendarDay(date: currentDate, belongsToDisplayedMonth: belongsToDisplayedMonth))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private func moodColor(for date: Date) -> Color? {
        let dateStr = dateFormatter.string(from: date)
        guard let entry = moodVM.savedMoods
            .first(where: { $0.date.hasPrefix(dateStr) })
        else {
            return nil
        }
        return colorForMood(entry.mood)
    }
    
    private func colorForMood(_ mood: String) -> Color {
        switch mood {
        case "angry":   return Color(hex: "#E27D60")
        case "sad":     return Color(hex: "#9EBEF0")
        case "neutral": return Color(hex: "#F6B6B6")
        case "happy":   return Color(hex: "#9CCDB4")
        case "joy":     return Color(hex: "#F9E49B")
        default:        return .gray
        }
    }
}
