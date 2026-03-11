import SwiftUI

struct StatsView: View {
    @EnvironmentObject var moodVM: MoodViewModel
    
    var body: some View {
        ScrollView {
            CalendarView()
                .padding(.top, 10)
            
            WeeklyStatsChartView()
                .padding(.top, 10)
            
            StatsChartView()
                .padding(.bottom, 30)
        }
        .background(Color(hex: "#F8F3ED").ignoresSafeArea())
        .onAppear {
            Task {
                await moodVM.loadSavedMoods()
            }
        }
    }
}
