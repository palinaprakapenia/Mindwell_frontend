import Foundation
import SwiftUI
import SocketIO

@MainActor
class ChallengesViewModel: ObservableObject {
    @Published var activeChallenge: ChallengeDisplay?
    @Published var availableChallenges: [ChallengeDisplay] = []
    @Published var completedChallenges: [ChallengeDisplay] = []
    @Published var isLoading = true
    @Published var activeUserTaskId: String = ""
    @Published var errorMessage: String?
    
    private let activeUserTaskIdKey = "activeUserTaskId"
    private var userLevel: Int = 1
    private var socket: SocketIOClient!
    
    weak var userProgressVM: UserProgressViewModel?
    
    static var shared: ChallengesViewModel?
    
    init(userLevel: Int = 1, userProgressVM: UserProgressViewModel? = nil) {
        self.userLevel = userLevel
        self.userProgressVM = userProgressVM
        ChallengesViewModel.shared = self
        
        if let saved = UserDefaults.standard.string(forKey: activeUserTaskIdKey), !saved.isEmpty {
            self.activeUserTaskId = saved
        }
        
        setupSocket()
    }
    
    private func setupSocket() {
        let manager = SocketManager(socketURL: URL(string: API.baseURL)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) { _, _ in
            print("Challenges socket connected")
        }
        
        socket.on("challengeUpdated") { [weak self] data, _ in
            guard let self = self else { return }
            Task { await self.loadAll() }
        }
        
        socket.connect()
    }
    
    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        
        do {
            let globalTasks: [TaskModel] = try await NetworkManager.shared.get([TaskModel].self, from: "/tasks?type=global")
            let myTasks: [UserTaskResponse] = try await NetworkManager.shared.get([UserTaskResponse].self, from: "/tasks/my")
            
            var available: [ChallengeDisplay] = []
            var completed: [ChallengeDisplay] = []
            
            for task in globalTasks {
                let userTask = myTasks.first { $0.taskId == task.id }
                let isCompleted = userTask?.completed ?? false
                let isActive = task.type == "global" ? (userTask?.id == activeUserTaskId && !isCompleted) : false
                
                var completedToday = task.code.contains("streak") ? (userTask?.isDailyCompleted ?? false) : false
                
                var challenge = ChallengeDisplay(
                    task: task,
                    progress: userTask?.currentCount ?? 0,
                    target: task.targetCount ?? 1,
                    isActive: isActive,
                    isCompleted: isCompleted,
                    isUnlocked: userLevel >= (task.requiredLevel ?? 1)
                )
                challenge.completedToday = completedToday
                
                if isCompleted {
                    completed.append(challenge)
                } else {
                    available.append(challenge)
                }
            }
            
            availableChallenges = available
            completedChallenges = completed
            
            activeChallenge = available.first { $0.isActive }
            
            if activeChallenge == nil, let userTaskForActive = myTasks.first(where: { $0.id == activeUserTaskId }) {
                if let taskModel = globalTasks.first(where: { $0.id == userTaskForActive.taskId }) {
                    activeChallenge = ChallengeDisplay(
                        task: taskModel,
                        progress: userTaskForActive.currentCount ?? 0,
                        target: taskModel.targetCount ?? 1,
                        isActive: true,
                        isCompleted: userTaskForActive.completed,
                        isUnlocked: userLevel >= (taskModel.requiredLevel ?? 1)
                    )
                }
            }
            
        } catch {
            errorMessage = "Failed to load challenges: \(error)"
            print(error)
        }
    }
    
    func startChallenge(_ display: ChallengeDisplay) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let response: UserTaskResponse = try await NetworkManager.shared.post(UserTaskResponse.self, to: "/tasks/\(display.task.id)/take", body: EmptyResponse())
                self.activeUserTaskId = response.id
                UserDefaults.standard.set(response.id, forKey: activeUserTaskIdKey)
                await loadAll()
            } catch {
                errorMessage = "Failed to start challenge: \(error)"
                print(error)
            }
        }
    }
    
    func resetActiveChallenge() async {
        guard !activeUserTaskId.isEmpty else { return }
        do {
            try await NetworkManager.shared.delete(to: "/tasks/\(activeUserTaskId)/abandon")
            UserDefaults.standard.removeObject(forKey: activeUserTaskIdKey)
            self.activeUserTaskId = ""
            self.activeChallenge = nil
            await loadAll()
        } catch {
            errorMessage = "Failed to reset challenge: \(error)"
            print(error)
        }
    }
    
    func updateUserLevel(_ level: Int) {
        userLevel = level
        Task { await loadAll() }
    }
    
    func markTodayCompleted(for challengeId: String) async {
        availableChallenges = availableChallenges.map { challenge in
            var updated = challenge
            if challenge.id == challengeId { updated.completedToday = true }
            return updated
        }
        
        if var active = activeChallenge, active.id == challengeId {
            active.completedToday = true
            activeChallenge = active
        }
        
        await loadAll()
    }
    
    struct EmptyResponse: Codable {}
}
