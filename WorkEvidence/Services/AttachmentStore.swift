import Foundation

struct ImportedEvidenceFile {
    let originalFilename: String
    let relativePath: String
    let byteCount: Int64
}

enum AttachmentStore {
    private static let rootFolderName = "EvidenceFiles"

    static func rootDirectory() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = appSupport
            .appendingPathComponent("WorkEvidence", isDirectory: true)
            .appendingPathComponent(rootFolderName, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func importFiles(_ urls: [URL], for entryID: UUID) throws -> [ImportedEvidenceFile] {
        let root = try rootDirectory()
        let entryFolder = root.appendingPathComponent(entryID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: entryFolder, withIntermediateDirectories: true)

        return try urls.map { sourceURL in
            let didAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess { sourceURL.stopAccessingSecurityScopedResource() }
            }

            let cleanName = sourceURL.lastPathComponent.replacingOccurrences(of: "/", with: "-")
            let uniqueName = "\(UUID().uuidString)-\(cleanName)"
            let destination = entryFolder.appendingPathComponent(uniqueName)
            try FileManager.default.copyItem(at: sourceURL, to: destination)

            let values = try destination.resourceValues(forKeys: [.fileSizeKey])
            let relative = "\(entryID.uuidString)/\(uniqueName)"
            return ImportedEvidenceFile(
                originalFilename: cleanName,
                relativePath: relative,
                byteCount: Int64(values.fileSize ?? 0)
            )
        }
    }

    static func url(for relativePath: String) -> URL? {
        guard let root = try? rootDirectory() else { return nil }
        return root.appendingPathComponent(relativePath)
    }

    static func delete(relativePath: String) {
        guard let url = url(for: relativePath) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
