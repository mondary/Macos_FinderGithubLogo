import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    private let gitBadgeId = "git"
    private let githubBadgeId = "github"
    private let logURL = URL(fileURLWithPath: "/tmp/FinderGitBadge.log")

    override init() {
        super.init()

        let controller = FIFinderSyncController.default()
        var roots: [URL] = []

        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            roots.append(docs)
        }

        // Explicit projects root inside Documents to ensure Finder requests badges in that tree.
        let projectsRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents")
            .appendingPathComponent("GitHub/PROJECTS")
        if FileManager.default.fileExists(atPath: projectsRoot.path) {
            roots.append(projectsRoot)
        }

        // If Documents is iCloud-backed, add the iCloud Documents path too.
        let iCloudDocs = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
            .appendingPathComponent("Documents")
        if FileManager.default.fileExists(atPath: iCloudDocs.path) {
            roots.append(iCloudDocs)
        }

        if roots.isEmpty {
            roots = [FileManager.default.homeDirectoryForCurrentUser]
        }

        controller.directoryURLs = Set(roots)
        appendLog("init: watching \(roots.map { $0.path }.joined(separator: ", "))")

        // Menu is provided via override menu(for:).

        let gitBadge = BadgeImageFactory.makeBadge(text: "git", background: NSColor.systemRed)
        let githubBadge = BadgeImageFactory.makeBadge(text: "GH", background: NSColor.black)

        controller.setBadgeImage(gitBadge, label: "Git Repository", forBadgeIdentifier: gitBadgeId)
        controller.setBadgeImage(githubBadge, label: "GitHub Repository", forBadgeIdentifier: githubBadgeId)
    }

    override func requestBadgeIdentifier(for url: URL) {
        let badge = GitDetector.shared.badgeIdentifier(for: url)
        FIFinderSyncController.default().setBadgeIdentifier(badge ?? "", for: url)
        appendLog("badge request: \(url.path) -> \(badge ?? "none")")
    }

    override func beginObservingDirectory(at url: URL) {
        appendLog("begin observing: \(url.path)")
    }

    override func endObservingDirectory(at url: URL) {
        appendLog("end observing: \(url.path)")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "FinderGitBadge")
        menu.addItem(withTitle: "FinderGitBadge: Ping", action: #selector(ping), keyEquivalent: "")
        return menu
    }
}

private enum BadgeImageFactory {
    static func makeBadge(text: String, background: NSColor) -> NSImage {
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 7, yRadius: 7)
        background.setFill()
        path.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ]

        let textRect = NSRect(x: 0, y: 7, width: size.width, height: 18)
        (text as NSString).draw(in: textRect, withAttributes: attrs)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

extension FinderSync {
    @objc private func ping() {
        appendLog("ping")
    }

    private func appendLog(_ line: String) {
        let text = "\(Date()): \(line)\n"
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                    try? handle.close()
                    return
                }
            }
            try? data.write(to: logURL, options: .atomic)
        }
    }
}
