# FinderGitBadge

![Project icon](icon.png)

[🇫🇷 FR](README.md) · [🇬🇧 EN](README_en.md)

✨ Affiche un badge Git/GitHub dans le Finder et applique une icône personnalisée aux dossiers de projets GitHub.

## ✅ Fonctionnalités
- Badge Finder Sync pour dossiers Git / GitHub
- Script pour changer l’icône des dossiers GitHub
- Menubar app avec actions rapides (refresh, logs, script)

## 🧠 Utilisation
- Lancer l’app pour activer la menubar
- Activer l’extension Finder dans les réglages macOS
- Exécuter le script pour appliquer les icônes

## ⚙️ Réglages
- Dossiers observés par défaut : `~/Documents` et `~/Documents/GitHub/PROJECTS`

## 🧾 Commandes
- `Refresh Finder Badges`
- `Open Log`
- `Run GitHub Folder Icon Script`
- `Quit`

## 📦 Build & Package
```bash
xcodegen generate
xcodebuild -project FinderGitBadge.xcodeproj -scheme FinderGitBadge -configuration Debug build
```

## 🧪 Installation (Antigravity)
- Copier l’app dans `/Applications`
- Activer l’extension Finder
- Relancer Finder si besoin

## 🧾 Changelog
- 1.0.0 : Première version (badge + script + menubar)

## 🔗 Liens
- EN README : README_en.md
