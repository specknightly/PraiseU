import Foundation
import SwiftData

@Model
final class RequestItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var receivedAt: Date
    var mailMessageID: String
    var sourceAccount: String
    var sourceMailbox: String
    var subject: String
    var sender: String
    var body: String
    var digest: String
    var inferredContext: String
    var draftResponse: String
    var priority: String
    var status: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        receivedAt: Date = .now,
        mailMessageID: String,
        sourceAccount: String,
        sourceMailbox: String,
        subject: String,
        sender: String,
        body: String,
        digest: String = "",
        inferredContext: String = "",
        draftResponse: String = "",
        priority: String = "Unclassified",
        status: String = "New"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.receivedAt = receivedAt
        self.mailMessageID = mailMessageID
        self.sourceAccount = sourceAccount
        self.sourceMailbox = sourceMailbox
        self.subject = subject
        self.sender = sender
        self.body = body
        self.digest = digest
        self.inferredContext = inferredContext
        self.draftResponse = draftResponse
        self.priority = priority
        self.status = status
    }
}
