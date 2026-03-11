import SwiftUI
import WebKit

struct YouTubePlayer: UIViewRepresentable {
    let url: URL
    let meditation: MeditationWithFavorite
    
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    @EnvironmentObject private var dailytaskVM: DailyTaskViewModel
    @EnvironmentObject private var challengesVM: ChallengesViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url?.absoluteString != url.absoluteString else { return }
        
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(meditation: meditation, dailytaskVM: dailytaskVM, challengesVM: challengesVM)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        private let meditation: MeditationWithFavorite
        private let dailytaskVM: DailyTaskViewModel
        private let challengesVM: ChallengesViewModel
        private var hasSentProgress = false
        
        init(meditation: MeditationWithFavorite, dailytaskVM: DailyTaskViewModel, challengesVM: ChallengesViewModel) {
            self.meditation = meditation
            self.dailytaskVM = dailytaskVM
            self.challengesVM = challengesVM
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !hasSentProgress else { return }
            hasSentProgress = true
            
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self else { return }
                Task {
                    await self.sendProgress()
                }
            }
        }
        
        private func sendProgress() async {
            let minutesString = meditation.duration
                .replacingOccurrences(of: " min", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            let deltaMinutes = Int(minutesString) ?? 10
            
            let body: [String: Any] = [
                "deltaCount": 1,
                "deltaMinutes": deltaMinutes,
                "category": meditation.category,
                "playedAt": ISO8601DateFormatter().string(from: Date()),
                "meditationId": meditation.id
            ]
            
            await dailytaskVM.loadDailyTask()
            
            if !dailytaskVM.userTaskId.isEmpty {
                await postProgress(to: dailytaskVM.userTaskId, body: body, isDaily: true)
            }
            
            if !challengesVM.activeUserTaskId.isEmpty, let activeChallengeId = challengesVM.activeChallenge?.id {
                await postProgress(to: challengesVM.activeUserTaskId, body: body, isDaily: false, challengeId: activeChallengeId)
            }
        }
        
        private func postProgress(to taskId: String, body: [String: Any], isDaily: Bool, challengeId: String? = nil) async {
            guard let url = URL(string: "\(API.baseURL)/tasks/\(taskId)/progress") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = KeychainHelper.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch { return }
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    await MainActor.run {
                        Task {
                            if isDaily {
                                await dailytaskVM.loadDailyTask()
                            }
                            
                            NotificationCenter.default.post(name: .pointsUpdated, object: nil)
                            
                            if let challengeId = challengeId {
                                await challengesVM.markTodayCompleted(for: challengeId)
                            }
                        }
                    }
                }
            } catch {}
        }
    }
}
