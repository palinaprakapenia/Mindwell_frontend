import Foundation

struct ChallengeDisplay: Identifiable, Equatable {
    let id: String
    let task: TaskModel
    
    var progress: Int
    let target: Int
    
    let isActive: Bool
    var isCompleted: Bool
    let isUnlocked: Bool
    
    var completedToday: Bool = false
    
    var targetMeditationId: String?
    
    var isInProgress: Bool { isActive && !isCompleted }
    var progressRatio: Double { Double(progress) / Double(max(target, 1)) }
    
    var progressText: String {
        if task.title.lowercased().contains("dni") || task.title.lowercased().contains("dzień") {
            return "\(progress)/\(target) dni"
        } else if task.title.lowercased().contains("minut") {
            return "\(progress)/\(target) minut"
        } else {
            return "\(progress)/\(target)"
        }
    }
    
    init(
        task: TaskModel,
        progress: Int = 0,
        target: Int = 1,
        isActive: Bool = false,
        isCompleted: Bool = false,
        isUnlocked: Bool = false,
        completedToday: Bool = false
    ) {
        self.id = task.id
        self.task = task
        self.progress = progress
        self.target = target
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.isUnlocked = isUnlocked
        self.completedToday = completedToday
    }
}
