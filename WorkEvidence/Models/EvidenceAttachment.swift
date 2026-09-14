import Foundation
import SwiftData

@Model
final class EvidenceAttachment {
    @Attribute(.unique) var id: UUID
    var originalFilename: String
    var relativePath: String
    var addedAt: Date
    var byteCount: Int64
    var entry: Accomplishment?

    init(
        id: UUID = UUID(),
        originalFilename: String,
        relativePath: String,
        addedAt: Date = .now,
        byteCount: Int64 = 0,
        entry: Accomplishment? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.relativePath = relativePath
        self.addedAt = addedAt
        self.byteCount = byteCount
        self.entry = entry
    }
}
