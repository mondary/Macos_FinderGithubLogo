import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let logURL = URL(fileURLWithPath: "/tmp/FinderGitBadgeApp.log")

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
    }

    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.title = "GH"
            button.image = NSImage(systemSymbolName: "chevron.left.slash.chevron.right", accessibilityDescription: "GitHub")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Refresh Finder Badges", action: #selector(refreshFinderBadges), keyEquivalent: "r")
        menu.addItem(withTitle: "Open Log", action: #selector(openLog), keyEquivalent: "l")
        menu.addItem(withTitle: "Run GitHub Folder Icon Script", action: #selector(runIconScript), keyEquivalent: "g")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit FinderGitBadge", action: #selector(quit), keyEquivalent: "q")

        item.menu = menu
        statusItem = item
        appendLog("status bar created")
    }

    @objc private func refreshFinderBadges() {
        run("/usr/bin/pluginkit", ["-e", "use", "-i", "com.example.FinderGitBadge.FinderSync"])
        run("/usr/bin/killall", ["Finder"])
    }

    @objc private func openLog() {
        run("/usr/bin/open", ["/tmp/FinderGitBadge.log"])
    }

    @objc private func runIconScript() {
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("FinderGitBadge", isDirectory: true)
        guard let dir = supportDir else { return }
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let scriptURL = dir.appendingPathComponent("apply-github-folder-icons.sh")
        if let bundledPng = Bundle.main.url(forResource: "github", withExtension: "png") {
            let targetPng = dir.appendingPathComponent("github.png")
            _ = try? fm.removeItem(at: targetPng)
            try? fm.copyItem(at: bundledPng, to: targetPng)
        }
        let script = """
        #!/bin/bash
        set -euo pipefail

        ROOT="${1:-${HOME}/Documents}"
        LOG="/tmp/FinderGitBadge.log"
        CACHE_DIR="${HOME}/Library/Caches/FinderGitBadge"
        ICON_SVG="$CACHE_DIR/github-folder.svg"
        ICON_PNG="$CACHE_DIR/github-folder.png"
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        SOURCE_PNG="$SCRIPT_DIR/github.png"

        mkdir -p "$CACHE_DIR"

        echo "$(date): run icon script on $ROOT" >> "$LOG"

        ICON_FILE="$SOURCE_PNG"
        if [[ ! -f "$ICON_FILE" ]]; then
            cat > "$ICON_SVG" <<'SVG'
        <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
          <rect x="64" y="256" width="896" height="640" rx="64" fill="#111111"/>
          <rect x="64" y="160" width="448" height="160" rx="48" fill="#1E1E1E"/>
          <circle cx="768" cy="704" r="160" fill="#FFFFFF"/>
          <text x="768" y="744" font-size="120" font-family="Helvetica, Arial, sans-serif" text-anchor="middle" fill="#111111">GH</text>
        </svg>
        SVG
            qlmanage -t -s 1024 -o "$CACHE_DIR" "$ICON_SVG" >/dev/null 2>&1 || true
            if [[ -f "$CACHE_DIR/github-folder.svg.png" ]]; then
              mv -f "$CACHE_DIR/github-folder.svg.png" "$ICON_PNG"
            fi
            ICON_FILE="$ICON_PNG"
        fi

        if [[ ! -f "$ICON_FILE" ]]; then
          echo "$(date): failed to render PNG" >> "$LOG"
          exit 1
        fi

        if [[ ! -d "$ROOT" ]]; then
          echo "$(date): root not found: $ROOT" >> "$LOG"
          exit 1
        fi

        while IFS= read -r -d '' gitdir; do
          repo="$(dirname "$gitdir")"
          if git -C "$repo" remote -v 2>/dev/null | grep -qi "github.com"; then
            /usr/bin/swift - "$ICON_FILE" "$repo" <<'SWIFT' || true
        import AppKit
        import Foundation

        let iconPath = CommandLine.arguments[1]
        let targetPath = CommandLine.arguments[2]

        guard let image = NSImage(contentsOfFile: iconPath) else {
            exit(2)
        }

        let ok = NSWorkspace.shared.setIcon(image, forFile: targetPath, options: [])
        if !ok {
            exit(3)
        }
        SWIFT
            echo "$(date): icon set -> $repo" >> "$LOG"
          fi
        done < <(find "$ROOT" -name .git -type d -print0)

        killall Finder >/dev/null 2>&1 || true
        """
        try? script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let documentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents")
            .path
        run("/bin/bash", [scriptURL.path, documentsPath])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func run(_ cmd: String, _ args: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: cmd)
        task.arguments = args
        try? task.run()
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
