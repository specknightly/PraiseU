import XCTest
@testable import WorkEvidence

final class AttachmentStoreTests: XCTestCase {
    func testImportFilesCopiesContentAndReportsByteCount() throws {
        let entryID = UUID()
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        let contents = "evidence"
        try contents.write(to: sourceURL, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            cleanUpImportedEntry(entryID)
        }

        let imported = try AttachmentStore.importFiles([sourceURL], for: entryID)
        XCTAssertEqual(imported.count, 1)
        let file = try XCTUnwrap(imported.first)
        XCTAssertEqual(file.originalFilename, sourceURL.lastPathComponent)
        XCTAssertEqual(file.byteCount, Int64(contents.utf8.count))

        let storedURL = try XCTUnwrap(AttachmentStore.url(for: file.relativePath))
        XCTAssertEqual(try String(contentsOf: storedURL, encoding: .utf8), contents)
    }

    func testImportFilesSanitizesSlashesInFilename() throws {
        let entryID = UUID()
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try "x".write(to: sourceURL, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            cleanUpImportedEntry(entryID)
        }

        let imported = try AttachmentStore.importFiles([sourceURL], for: entryID)
        let file = try XCTUnwrap(imported.first)
        XCTAssertFalse(file.relativePath.dropFirst(entryID.uuidString.count + 1).contains("/"))
    }

    func testDeleteRemovesTheStoredFile() throws {
        let entryID = UUID()
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try "x".write(to: sourceURL, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            cleanUpImportedEntry(entryID)
        }

        let file = try XCTUnwrap(try AttachmentStore.importFiles([sourceURL], for: entryID).first)
        let storedURL = try XCTUnwrap(AttachmentStore.url(for: file.relativePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: storedURL.path))

        AttachmentStore.delete(relativePath: file.relativePath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storedURL.path))
    }

    private func cleanUpImportedEntry(_ entryID: UUID) {
        guard let root = try? AttachmentStore.rootDirectory() else { return }
        try? FileManager.default.removeItem(at: root.appendingPathComponent(entryID.uuidString, isDirectory: true))
    }
}
