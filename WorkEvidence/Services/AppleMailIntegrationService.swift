import Foundation
import AppKit
import SwiftData

struct AppleMailMailboxDescriptor: Identifiable, Hashable, Sendable {
    let accountName: String
    let mailboxPath: String

    var id: String { accountName + "\u{1F}" + mailboxPath }
    var displayName: String { "\(accountName) — \(mailboxPath)" }
}

struct AppleMailMessageSnapshot: Sendable {
    let messageID: String
    let subject: String
    let sender: String
    let receivedDateText: String
    let body: String
}

enum AppleMailIntegrationError: LocalizedError {
    case permissionDenied
    case mailUnavailable
    case mailboxNotFound
    case scriptFailure(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "macOS denied access to Mail. Open System Settings > Privacy & Security > Automation and allow Accomplishment Tracker to control Mail."
        case .mailUnavailable:
            return "Apple Mail could not be reached. Open Mail once, confirm your account is configured, then try again."
        case .mailboxNotFound:
            return "The selected Mail mailbox could not be found. Refresh the mailbox list and select it again."
        case .scriptFailure(let detail):
            return "Apple Mail automation failed: \(detail)"
        }
    }
}

@MainActor
enum AppleMailIntegrationService {
    private static let processedIDsKey = "appleMailProcessedMessageKeys"
    static let maxMessagesPerScan = 80

    static func availableMailboxes() throws -> [AppleMailMailboxDescriptor] {
        let source = #"""
        on walkMailboxes(accountName, boxList, parentPath)
            set outputText to ""
            tell application "Mail"
                repeat with boxRef in boxList
                    set boxName to name of boxRef as text
                    if parentPath is "" then
                        set fullPath to boxName
                    else
                        set fullPath to parentPath & "/" & boxName
                    end if
                    set outputText to outputText & accountName & tab & fullPath & linefeed
                    try
                        set childBoxes to mailboxes of boxRef
                        if (count of childBoxes) > 0 then
                            set outputText to outputText & my walkMailboxes(accountName, childBoxes, fullPath)
                        end if
                    end try
                end repeat
            end tell
            return outputText
        end walkMailboxes

        tell application "Mail"
            set outputText to ""
            repeat with acct in accounts
                set accountName to name of acct as text
                set outputText to outputText & my walkMailboxes(accountName, mailboxes of acct, "")
            end repeat
            return outputText
        end tell
        """#

        let raw = try runAppleScript(source)
        let rows = raw.split(whereSeparator: \.isNewline)
        let descriptors = rows.compactMap { row -> AppleMailMailboxDescriptor? in
            let parts = row.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return nil }
            let account = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let path = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !account.isEmpty, !path.isEmpty else { return nil }
            return AppleMailMailboxDescriptor(accountName: account, mailboxPath: path)
        }
        return Array(Set(descriptors)).sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    static func testAccess(accountName: String, mailboxPath: String) throws {
        let mailboxes = try availableMailboxes()
        guard mailboxes.contains(where: { $0.accountName == accountName && $0.mailboxPath == mailboxPath }) else {
            throw AppleMailIntegrationError.mailboxNotFound
        }
    }

    static func importNewMessages(
        accountName: String,
        mailboxPath: String,
        modelContext: ModelContext
    ) throws -> [Accomplishment] {
        let snapshots = try fetchMessageSnapshots(accountName: accountName, mailboxPath: mailboxPath, limit: maxMessagesPerScan)
        var processed = Set(UserDefaults.standard.stringArray(forKey: processedIDsKey) ?? [])
        var newlyProcessedKeys: [String] = []
        var importedEntries: [Accomplishment] = []

        for message in snapshots {
            let key = "\(accountName)|\(mailboxPath)|\(message.messageID)"
            guard !processed.contains(key) else { continue }

            let title = message.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Email evidence from \(message.sender)"
                : message.subject

            let entry = Accomplishment(date: .now, title: title, category: .other)
            entry.context = """
            Imported from Apple Mail evidence mailbox.

            From: \(message.sender)
            Received: \(message.receivedDateText)

            \(message.body.prefix(10000))
            """
            entry.evidenceNotes = "Imported automatically from Apple Mail: \(accountName) / \(mailboxPath). Mail message ID: \(message.messageID)"
            entry.stakeholders = message.sender
            entry.tagsText = "source:Apple Mail,email-evidence,needs-review"

            modelContext.insert(entry)
            importedEntries.append(entry)
            processed.insert(key)
            newlyProcessedKeys.append(key)
        }

        if !importedEntries.isEmpty {
            try modelContext.save()
            let retained = Array(processed.suffix(5000))
            UserDefaults.standard.set(retained, forKey: processedIDsKey)
        }

        return importedEntries
    }

    static func fetchMessageSnapshots(accountName: String, mailboxPath: String, limit: Int) throws -> [AppleMailMessageSnapshot] {
        let escapedAccount = appleScriptEscaped(accountName)
        let escapedPath = appleScriptEscaped(mailboxPath)
        let source = #"""
        on splitPath(pathText)
            set oldDelimiters to AppleScript's text item delimiters
            set AppleScript's text item delimiters to "/"
            set pathParts to text items of pathText
            set AppleScript's text item delimiters to oldDelimiters
            return pathParts
        end splitPath

        on findMailbox(accountName, pathText)
            tell application "Mail"
                set targetAccount to first account whose name is accountName
                set parts to my splitPath(pathText)
                set currentBoxes to mailboxes of targetAccount
                set currentBox to missing value
                repeat with partName in parts
                    set wantedName to partName as text
                    set currentBox to first item of (currentBoxes whose name is wantedName)
                    set currentBoxes to mailboxes of currentBox
                end repeat
                return currentBox
            end tell
        end findMailbox

        on cleanField(valueText)
            set t to valueText as text
            set unitSep to character id 31
            set recSep to character id 30
            set oldDelimiters to AppleScript's text item delimiters
            set AppleScript's text item delimiters to unitSep
            set p to text items of t
            set AppleScript's text item delimiters to " "
            set t to p as text
            set AppleScript's text item delimiters to recSep
            set p to text items of t
            set AppleScript's text item delimiters to " "
            set t to p as text
            set AppleScript's text item delimiters to oldDelimiters
            return t
        end cleanField

        tell application "Mail"
            set targetBox to my findMailbox("ACCOUNT_PLACEHOLDER", "PATH_PLACEHOLDER")
            if targetBox is missing value then error "Mailbox not found"
            set msgs to messages of targetBox
            set totalCount to count of msgs
            if totalCount > LIMIT_PLACEHOLDER then
                set readCount to LIMIT_PLACEHOLDER
            else
                set readCount to totalCount
            end if
            set unitSep to character id 31
            set recSep to character id 30
            set outputText to ""
            repeat with i from 1 to readCount
                set m to item i of msgs
                try
                    set mid to message id of m as text
                on error
                    set mid to id of m as text
                end try
                try
                    set subj to subject of m as text
                on error
                    set subj to ""
                end try
                try
                    set fromText to sender of m as text
                on error
                    set fromText to ""
                end try
                try
                    set receivedText to date received of m as text
                on error
                    set receivedText to ""
                end try
                try
                    set bodyText to content of m as text
                on error
                    set bodyText to ""
                end try
                if (length of bodyText) > 12000 then set bodyText to text 1 thru 12000 of bodyText
                set outputText to outputText & my cleanField(mid) & unitSep & my cleanField(subj) & unitSep & my cleanField(fromText) & unitSep & my cleanField(receivedText) & unitSep & my cleanField(bodyText) & recSep
            end repeat
            return outputText
        end tell
        """#
            .replacingOccurrences(of: "ACCOUNT_PLACEHOLDER", with: escapedAccount)
            .replacingOccurrences(of: "PATH_PLACEHOLDER", with: escapedPath)
            .replacingOccurrences(of: "LIMIT_PLACEHOLDER", with: String(max(1, limit)))

        let raw = try runAppleScript(source)
        let recordSeparator = Character(UnicodeScalar(30))
        let unitSeparator = Character(UnicodeScalar(31))

        return raw.split(separator: recordSeparator, omittingEmptySubsequences: true).compactMap { record in
            let fields = record.split(separator: unitSeparator, maxSplits: 4, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 5, !fields[0].isEmpty else { return nil }
            return AppleMailMessageSnapshot(
                messageID: fields[0],
                subject: fields[1],
                sender: fields[2],
                receivedDateText: fields[3],
                body: fields[4]
            )
        }
    }

    private static func runAppleScript(_ source: String) throws -> String {
        guard let script = NSAppleScript(source: source) else {
            throw AppleMailIntegrationError.scriptFailure("Could not create AppleScript.")
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let number = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            if number == -1743 { throw AppleMailIntegrationError.permissionDenied }
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "Unknown AppleScript error"
            if message.localizedCaseInsensitiveContains("not found") { throw AppleMailIntegrationError.mailboxNotFound }
            throw AppleMailIntegrationError.scriptFailure(message)
        }
        return result.stringValue ?? ""
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
