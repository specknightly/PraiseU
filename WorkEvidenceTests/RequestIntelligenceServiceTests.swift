import XCTest
@testable import WorkEvidence

@MainActor
final class RequestIntelligenceServiceTests: XCTestCase {
    func testParsePlainHeadings() {
        let text = """
        DIGEST
        User needs a password reset.

        CONTEXT
        No relevant prior knowledge was found.

        PRIORITY
        High

        DRAFT RESPONSE
        Hi, I can help with that.
        """
        let result = RequestIntelligenceService.parse(text)
        XCTAssertEqual(result.digest, "User needs a password reset.")
        XCTAssertEqual(result.context, "No relevant prior knowledge was found.")
        XCTAssertEqual(result.priority, "High")
        XCTAssertEqual(result.response, "Hi, I can help with that.")
    }

    /// The on-device model is not guaranteed to reproduce plain-text headings; it may wrap them
    /// in markdown emphasis or use heading markers instead.
    func testParseToleratesMarkdownDecoratedHeadings() {
        let text = """
        **DIGEST**
        Needs VPN access restored.

        ### CONTEXT
        Related to a prior VPN outage.

        **PRIORITY:**
        Urgent

        # DRAFT RESPONSE
        On it right away.
        """
        let result = RequestIntelligenceService.parse(text)
        XCTAssertEqual(result.digest, "Needs VPN access restored.")
        XCTAssertEqual(result.context, "Related to a prior VPN outage.")
        XCTAssertEqual(result.priority, "Urgent")
        XCTAssertEqual(result.response, "On it right away.")
    }

    func testParseDefaultsPriorityToNormalWhenUnrecognized() {
        let text = """
        DIGEST
        Something.

        CONTEXT
        Nothing relevant.

        PRIORITY
        Whenever is fine

        DRAFT RESPONSE
        Sure.
        """
        XCTAssertEqual(RequestIntelligenceService.parse(text).priority, "Normal")
    }

    func testParseReturnsEmptySectionsWhenHeadingsAreMissing() {
        let result = RequestIntelligenceService.parse("The model said something unstructured.")
        XCTAssertEqual(result.digest, "")
        XCTAssertEqual(result.priority, "Normal")
    }

    func testPriorKnowledgeRanksHigherOverlapFirst() {
        let strongMatch = Accomplishment(date: .now, title: "Migrated Exchange mailboxes", context: "Exchange migration project")
        let weakMatch = Accomplishment(date: .now, title: "Replaced a keyboard", context: "Routine hardware swap")
        let request = RequestItem(
            mailMessageID: "1",
            sourceAccount: "acct",
            sourceMailbox: "box",
            subject: "Exchange mailbox migration question",
            sender: "user@example.com",
            body: "Can you help with the Exchange migration project?"
        )
        let knowledge = RequestIntelligenceService.priorKnowledge(for: request, accomplishments: [weakMatch, strongMatch])
        let strongRange = knowledge.range(of: "Migrated Exchange mailboxes")
        let weakRange = knowledge.range(of: "Replaced a keyboard")
        XCTAssertNotNil(strongRange)
        if let strongRange, let weakRange {
            XCTAssertTrue(strongRange.lowerBound < weakRange.lowerBound)
        }
    }

    func testPriorKnowledgeReportsNoMatchWhenNothingOverlaps() {
        let request = RequestItem(mailMessageID: "1", sourceAccount: "a", sourceMailbox: "b", subject: "zzz", sender: "s", body: "zzz")
        let knowledge = RequestIntelligenceService.priorKnowledge(for: request, accomplishments: [])
        XCTAssertEqual(knowledge, "No clearly related prior accomplishment was found.")
    }
}
