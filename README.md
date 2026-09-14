<h1 align="center">Coursy</h1>

<p align="center">
  Mobile-First-Plattform zur Entdeckung & Verwaltung von Bildungskursen –<br>
  Flutter-App mit Laravel-Backend.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=flutter&logoColor=white">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.8%2B-02569B?logo=flutter&logoColor=white">
  <img alt="Backend" src="https://img.shields.io/badge/Backend-Laravel-FF2D20?logo=laravel&logoColor=white">
  <img alt="Push" src="https://img.shields.io/badge/Push-Firebase%20Cloud%20Messaging-FFCA28?logo=firebase&logoColor=black">
</p>

---

## Über das Projekt

**Coursy** ist eine mobile Plattform, auf der Lernende Bildungskurse, Institute und Dozenten entdecken,
vergleichen und verfolgen können. Die App bietet eine strukturierte Such- und Filterfunktion, persönliche
Favoritenlisten sowie Push-Benachrichtigungen zu neuen Kursen und Aktivitäten.

## Funktionsumfang

| Bereich | Beschreibung |
|---|---|
| 🔐 **Authentifizierung** | Registrierung/Login inkl. Telefonverifizierung und sicherer Session-Verwaltung |
| 📚 **Kurse** | Durchsuchen, Filtern und Detailansicht von Bildungskursen |
| 🏫 **Institute** | Übersicht und Profile teilnehmender Bildungseinrichtungen |
| 👨‍🏫 **Dozenten** | Profile und zugehörige Kurse je Dozent |
| ⭐ **Favoriten** | Kurse und Institute für später speichern |
| 🔍 **Suche** | Volltextsuche über Kurse, Institute und Dozenten |
| 🔔 **Benachrichtigungen** | Push-Benachrichtigungen (Firebase Cloud Messaging) & In-App-Benachrichtigungscenter |
| 👤 **Profil** | Persönliche Daten, Profilbild, Kontoeinstellungen |
| 🌐 **Onboarding** | Geführte Einführung für neue Nutzer |

## Architektur

```
┌───────────────────────┐        HTTPS / REST        ┌───────────────────────────┐
│     Coursy Flutter     │ ◄────────────────────────► │      Laravel Backend      │
│  (Android · iOS · Web) │                             │   coursy.sy/api            │
└───────────────────────┘                             └───────────────────────────┘
          │
          ▼
  Firebase Cloud Messaging
  (Push-Benachrichtigungen)
```

- **State Management:** [`GetX`](https://pub.dev/packages/get) – Controller, Bindings & Navigation
- **Netzwerk:** [`dio`](https://pub.dev/packages/dio) für die REST-Kommunikation mit dem Backend
- **Lokaler Speicher:** [`get_storage`](https://pub.dev/packages/get_storage) für App-Einstellungen,
  [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) für sensible Session-Daten
- **Push-Benachrichtigungen:** Firebase Cloud Messaging + `flutter_local_notifications` + `workmanager` für
  Hintergrundverarbeitung
- **Backend:** Laravel-API unter `coursy.sy/api`

## Projektstruktur

```
Course/
├── my_app/                  # Flutter-App
│   └── lib/
│       ├── core/             # Config, Netzwerk-Client, Storage, Session, Push, Bindings
│       ├── modules/          # Fachmodule (auth, courses, institutes, instructors,
│       │                     #   favorites, search, notifications, profile, onboarding …)
│       ├── routes/           # App-Navigation/Routing
│       ├── theme/            # Corporate Design
│       └── widgets/          # Wiederverwendbare UI-Komponenten
└── server/                  # Backend-bezogene Laravel-Anpassungen
```

## Erste Schritte

### Voraussetzungen

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.8
- Firebase-Projekt für Push-Benachrichtigungen (bereits unter `coursy-ec580` konfiguriert)

### Installation

```bash
cd my_app
flutter pub get
```

### App starten

Standardmäßig verbindet sich die App mit dem produktiven Backend (`https://coursy.sy/api`). Für lokale
Backend-Entwicklung kann die API-Basis-URL überschrieben werden:

```bash
flutter run --dart-define=API_BASE_URL=http://<lokale-ip>:8000/api
```

Für die Web-Entwicklung in Chrome (inkl. lokalem CORS-Proxy):

```bash
./scripts/run_web_chrome.ps1
```

### Tests ausführen

```bash
flutter test
```

## Sicherheit & Datenschutz

- Sensible Session-Daten (Zugangstoken, Nutzerinformationen) werden ausschließlich über
  `flutter_secure_storage` verschlüsselt auf dem Gerät abgelegt.
- Die Kommunikation mit dem Backend erfolgt ausschließlich über HTTPS.
- Firebase-Client-Konfigurationswerte sind – wie von Google vorgesehen – öffentliche
  App-Identifikatoren, keine geheimen Zugangsdaten.

## Status

Aktiv in Entwicklung.

---

<p align="center"><sub>© Coursy – Alle Rechte vorbehalten.</sub></p>
