import XCTest
@testable import WorkEvidence

final class EvidenceIntelligenceServiceTests: XCTestCase {
    func testParsesPlainClaimStrengthAndWorkLevel() {
        let text = """
        CLAIM_STRENGTH: 82
        WORK_LEVEL: SPECIALIST
        Contribution
        Did the thing.
        """
        let parsed = EvidenceIntelligenceService.parseProfessionalIntelligence(text)
        XCTAssertEqual(parsed.claimStrength, 82)
        XCTAssertEqual(parsed.workLevel, .specialist)
    }

    /// The model sometimes wraps the machine-readable lines in markdown emphasis; `.hasPrefix`
    /// on the raw line would previously miss this entirely and silently score everything 0/Routine.
    func testParsesMarkdownDecoratedLines() {
        let text = """
        **CLAIM_STRENGTH:** 57
        **WORK_LEVEL:** PROJECT_OWNER
        """
        let parsed = EvidenceIntelligenceService.parseProfessionalIntelligence(text)
        XCTAssertEqual(parsed.claimStrength, 57)
        XCTAssertEqual(parsed.workLevel, .projectOwner)
    }

    func testClampsClaimStrengthToZeroToHundred() {
        let text = "CLAIM_STRENGTH: 150\nWORK_LEVEL: ROUTINE"
        XCTAssertEqual(EvidenceIntelligenceService.parseProfessionalIntelligence(text).claimStrength, 100)
    }

    func testDefaultsToRoutineAndZeroWhenLinesAreMissing() {
        let parsed = EvidenceIntelligenceService.parseProfessionalIntelligence("No structured output at all.")
        XCTAssertEqual(parsed.claimStrength, 0)
        XCTAssertEqual(parsed.workLevel, .routine)
    }

    func testEachWorkLevelKeywordMaps() {
        let cases: [(String, WorkLevel)] = [
            ("STRATEGIC", .strategic),
            ("PROJECT_OWNER", .projectOwner),
            ("SPECIALIST", .specialist),
            ("ADVANCED", .advanced),
            ("ROUTINE", .routine)
        ]
        for (keyword, expected) in cases {
            let text = "CLAIM_STRENGTH: 10\nWORK_LEVEL: \(keyword)"
            XCTAssertEqual(EvidenceIntelligenceService.parseProfessionalIntelligence(text).workLevel, expected, "keyword \(keyword)")
        }
    }
}
