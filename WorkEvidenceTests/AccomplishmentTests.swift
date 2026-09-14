import XCTest
@testable import WorkEvidence

final class AccomplishmentTests: XCTestCase {
    func testTagsSplitsTrimsAndDropsEmpties() {
        let entry = Accomplishment(tagsText: " migration, outage ,,automation ")
        XCTAssertEqual(entry.tags, ["migration", "outage", "automation"])
    }

    func testTagsIsEmptyForBlankString() {
        let entry = Accomplishment(tagsText: "   ")
        XCTAssertTrue(entry.tags.isEmpty)
    }

    func testSearchBlobIsLowercasedAndIncludesOptionalFields() {
        let entry = Accomplishment(title: "Migrated DNS", context: "Legacy DNS Outage")
        entry.humanValueAnalysis = "Required Judgment"
        XCTAssertTrue(entry.searchBlob.contains("migrated dns"))
        XCTAssertTrue(entry.searchBlob.contains("legacy dns outage"))
        XCTAssertTrue(entry.searchBlob.contains("required judgment"))
    }

    func testCategoryRoundTripsThroughRawValue() {
        let entry = Accomplishment()
        entry.category = .security
        XCTAssertEqual(entry.categoryRaw, "Security")
        XCTAssertEqual(entry.category, .security)
    }

    func testCategoryFallsBackToOtherForUnknownRawValue() {
        let entry = Accomplishment()
        entry.categoryRaw = "Not A Real Category"
        XCTAssertEqual(entry.category, .other)
    }

    func testResponsibilityScopeFallsBackToUnclassified() {
        let entry = Accomplishment()
        entry.responsibilityScopeRaw = "Garbage"
        XCTAssertEqual(entry.responsibilityScope, .unclassified)
    }

    func testWorkLevelFallsBackToUnclassifiedWhenRawIsNil() {
        let entry = Accomplishment()
        XCTAssertNil(entry.workLevelRaw)
        XCTAssertEqual(entry.workLevel, .unclassified)
    }
}
