import XCTest
@testable import WorkEvidence

final class ExportServiceTests: XCTestCase {
    func testEscapeHandlesAllFiveReservedCharacters() {
        let escaped = ExportService.escape("<script>alert(\"x\" & 'y')</script>")
        XCTAssertEqual(escaped, "&lt;script&gt;alert(&quot;x&quot; &amp; &#39;y&#39;)&lt;/script&gt;")
        XCTAssertFalse(escaped.contains("<"))
        XCTAssertFalse(escaped.contains(">"))
    }

    func testEscapeLeavesPlainTextUnchanged() {
        XCTAssertEqual(ExportService.escape("Migrated 40 accounts to Entra ID"), "Migrated 40 accounts to Entra ID")
    }

    func testAnnualReviewHTMLEscapesUntrustedTitleContent() {
        let entry = Accomplishment(title: "<img src=x onerror=alert(1)>")
        let html = ExportService.annualReviewHTML(entries: [entry], year: 2026)
        XCTAssertFalse(html.contains("<img src=x onerror=alert(1)>"))
        XCTAssertTrue(html.contains("&lt;img src=x onerror=alert(1)&gt;"))
    }

    func testAnnualReviewHTMLShowsPlaceholderWhenNoEntries() {
        let html = ExportService.annualReviewHTML(entries: [], year: 2026)
        XCTAssertTrue(html.contains("No entries for this year."))
    }
}
