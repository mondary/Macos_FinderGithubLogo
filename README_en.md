# FinderGitBadge

![Project icon](icon.png)

[🇬🇧 EN](README_en.md) · [🇫🇷 FR](README.md)

✨ Shows a Git/GitHub badge in Finder and applies a custom icon to GitHub project folders.

## ✅ Features
- Finder Sync badge for Git / GitHub folders
- Script to replace folder icons for GitHub repos
- Menubar app with quick actions (refresh, logs, script)

## 🧠 Usage
- Launch the app to enable the menubar
- Enable the Finder extension in macOS settings
- Run the script to apply icons

## ⚙️ Settings
- Default watched folders: `~/Documents` and `~/Documents/GitHub/PROJECTS`

## 🧾 Commands
- `Refresh Finder Badges`
- `Open Log`
- `Run GitHub Folder Icon Script`
- `Quit`

## 📦 Build & Package
```bash
xcodegen generate
xcodebuild -project FinderGitBadge.xcodeproj -scheme FinderGitBadge -configuration Debug build
```

## 🧪 Install (Antigravity)
- Copy the app to `/Applications`
- Enable the Finder extension
- Restart Finder if needed

## 🧾 Changelog
- 1.0.0: Initial version (badge + script + menubar)

## 🔗 Links
- FR README: README.md
