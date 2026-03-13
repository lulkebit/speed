# Speed

Native macOS-Menubar-App mit integriertem Internet-Speedtest im Dropdown.

## Was die erste Version kann

- lebt nur in der Menüleiste
- öffnet ein kompaktes, übersichtliches Dropdown mit Download, Upload, Ping und Reaktionszeit
- nutzt den nativen macOS-Speedtest `networkQuality`
- erlaubt erneutes Starten und Abbrechen einer laufenden Messung
- lässt sich als `.app`-Bundle bauen

## Voraussetzungen

- macOS 14 oder neuer
- Xcode Command Line Tools bzw. Xcode

## Entwicklung starten

```bash
swift build
swift run SpeedMenuBar
```

## Als App bauen

```bash
./scripts/build-app.sh
open dist/SpeedMenuBar.app
```

## Struktur

- `Sources/SpeedCore`: Parsing, Service und ViewModel
- `Sources/SpeedMenuBar`: SwiftUI-Menubar-App und Views
- `App/Info.plist`: App-Metadaten fuer das Bundle
- `scripts/build-app.sh`: erzeugt lokal das `.app`-Bundle
