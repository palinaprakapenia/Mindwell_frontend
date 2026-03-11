import Foundation
import CoreData

struct HistoryManager {
    static func save(meditation: MeditationWithFavorite, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        
        let fetchRequest: NSFetchRequest<WatchedMeditation> = WatchedMeditation.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@ AND watchedAt >= %@ AND watchedAt < %@",
            meditation.id,
            todayStart as NSDate,
            todayEnd as NSDate
        )
        
        do {
            let existing = try context.fetch(fetchRequest)
            
            if let existingEntry = existing.first {
                existingEntry.watchedAt = Date()
            } else {
                let watched = WatchedMeditation(context: context)
                watched.id = meditation.id
                watched.title = meditation.title
                watched.duration = meditation.duration
                watched.category = meditation.category
                watched.videoUrl = meditation.videoUrl
                watched.watchedAt = Date()
            }
            
            try context.save()
            
        } catch {
            print("Error saving history: \(error)")
        }
    }
}
