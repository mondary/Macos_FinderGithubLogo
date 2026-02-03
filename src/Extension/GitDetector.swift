import Foundation

final class GitDetector {
    static let shared = GitDetector()

    private struct CacheEntry {
        let badge: String?
        let timestamp: TimeInterval
    }

    private let queue = DispatchQueue(label: "GitDetector.queue")
    private var cache: [URL: CacheEntry] = [:]
    private let ttl: TimeInterval = 30

    private init() {}

    func badgeIdentifier(for url: URL) -> String? {
        let now = Date().timeIntervalSince1970
        return queue.sync {
            if let entry = cache[url], now - entry.timestamp < ttl {
                return entry.badge
            }

            let badge = computeBadge(for: url)
            cache[url] = CacheEntry(badge: badge, timestamp: now)
            return badge
        }
    }

    private func computeBadge(for url: URL) -> String? {
        guard isDirectory(url) else { return nil }

        let gitURL = url.appendingPathComponent(".git")
        var isDir: ObjCBool = false
        let fm = FileManager.default
        guard fm.fileExists(atPath: gitURL.path, isDirectory: &isDir) else { return nil }

        if isDir.boolValue {
            let isGitHub = configContainsGitHub(gitDir: gitURL)
            return isGitHub ? "github" : "git"
        }

        // .git is a file (worktree/submodule). Resolve gitdir.
        if let gitDir = resolveGitDir(from: gitURL) {
            let isGitHub = configContainsGitHub(gitDir: gitDir)
            return isGitHub ? "github" : "git"
        }

        return "git"
    }

    private func isDirectory(_ url: URL) -> Bool {
        do {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            guard values.isDirectory == true else { return false }
            if values.isPackage == true { return false }
            return true
        } catch {
            return false
        }
    }

    private func resolveGitDir(from gitFileURL: URL) -> URL? {
        guard let data = try? Data(contentsOf: gitFileURL),
              let content = String(data: data, encoding: .utf8) else { return nil }
        // Expected: "gitdir: /path" or "gitdir: relative/path"
        let prefix = "gitdir:"
        guard let range = content.range(of: prefix) else { return nil }
        let pathPart = content[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        if pathPart.hasPrefix("/") {
            return URL(fileURLWithPath: pathPart)
        }
        let base = gitFileURL.deletingLastPathComponent()
        return base.appendingPathComponent(pathPart)
    }

    private func configContainsGitHub(gitDir: URL) -> Bool {
        let configURL = gitDir.appendingPathComponent("config")
        guard let data = try? Data(contentsOf: configURL),
              let content = String(data: data, encoding: .utf8) else { return false }
        return content.contains("github.com")
    }
}
