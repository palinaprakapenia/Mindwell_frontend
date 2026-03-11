import Foundation

struct DailyTaskResponse: Codable {
    let task: TaskModel?
    let completed: Bool
    let userTaskId: String?
}
