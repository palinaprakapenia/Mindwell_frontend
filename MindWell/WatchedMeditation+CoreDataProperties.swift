import Foundation
import CoreData


extension WatchedMeditation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchedMeditation> {
        return NSFetchRequest<WatchedMeditation>(entityName: "WatchedMeditation")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var duration: String?
    @NSManaged public var category: String?
    @NSManaged public var watchedAt: Date?
    @NSManaged public var videoUrl: String?

}

extension WatchedMeditation : Identifiable {

}
