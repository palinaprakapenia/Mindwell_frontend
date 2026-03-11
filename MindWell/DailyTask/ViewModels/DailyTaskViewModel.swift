import Foundation

@MainActor
class DailyTaskViewModel: ObservableObject {
    @Published var dailyTask: TaskModel?
    @Published var dailyTaskCompleted = false
    @Published var userTaskId = ""
    
    var hasValidDailyTask: Bool {
        guard let task = dailyTask else { return dailyTaskCompleted }
        return task.type == "daily"
    }
    
    func loadDailyTask() async {
        do {
            let response: DailyTaskResponse = try await NetworkManager.shared.get(
                DailyTaskResponse.self,
                from: "/tasks/daily/today"
            )
            
            self.dailyTask = response.task
            self.dailyTaskCompleted = response.completed
            self.userTaskId = response.userTaskId ?? ""
            
            
        } catch {
            print("Error loading daily task: \(error)")
            self.dailyTask = nil
            self.dailyTaskCompleted = false
            self.userTaskId = ""
        }
    }
}
