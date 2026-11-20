# MOTOPRESTO for iOS

Native iOS app for **MOTOPRESTO** (formerly MotoHub), a marketplace in Uzbekistan for motorcycles, spare parts and accessories. It is written in Swift and SwiftUI and needs iOS 17 or later.

It looks and works like the [website](https://motopresto.online) on a phone and like the [Android app](https://github.com/Max19942008/MotoHub-App), page for page. All three use the same [backend](https://github.com/Max19942008/MotoHub) over GraphQL.

## Features

- **Site layout:** dark navbar (logo, login pill or bell and avatar, menu), a right-hand menu with UZ / RU / EN / KR flags, the floating **AI Assistant** pill and the **live chat** button.
- **Home:** hero video, carousels of trending, popular and top bikes, top spare parts and accessories, elite agents, and the site footer.
- **Bikes, spare parts, accessories:** the site's header card with the total, the sort menu, and filter menus for brand, type, condition, region, year and price. Infinite scroll and pull to refresh.
- **Detail pages:**
  - photos, price card, and the call, "Qiziqaman" (interest) and like buttons
  - dealer card, specs and description
  - reviews (bikes), similar listings
- **Agents:** search, sort, agent cards with likes; the agent page has a follow button, bike and review tabs.
- **Community:** boards, posts with likes, article page with comments, and a form to write an article.
- **Help centre and notifications:**
  - Help centre: notices and the FAQ.
  - Notifications: the bell with an unread count, mark all as read, delete.
- **My page:**
  - profile with photo upload
  - favourites, recently viewed, followers and followings, my articles
  - for dealers: my bikes and parts (active / blocked / archived) with an add and edit form and photo upload
- **Live chat:** the same WebSocket room as the website and the Android app.
- **AI assistant:** answers from MOTOPRESTO listings with tappable listing cards; answers can be reported.
- **Accounts:** log in and sign up with the website account. Tokens are kept in the Keychain and refreshed silently with rotating refresh tokens. You can delete your account in the app, as App Store Review Guideline 5.1.1(v) requires.

## Architecture

Clean architecture with one-way dependencies: **Presentation → Domain ← Data**. `App/` wires them together.

```
MotoHub/
  App/            entry point, composition root (AppContainer), Router (navigation + toasts), site shell
  Core/           config, brand theme (colors, Poppins), i18n, formatting
  Domain/         entities, filters, repository protocols, AppError (no UIKit, no networking)
  Data/
    Network/      GraphQL-over-HTTP client (JSON, multipart image upload), error translation
    GraphQLRepository.swift   every listing / agent / community / my-page / notification query
    Mapping.swift             JSON -> entities
    Auth/         AuthSession actor (single-flight token refresh), Keychain TokenStore, JWT, auth repository
    Assistant/    AI assistant repository
    Chat/         live chat WebSocket service
  Presentation/   SwiftUI screens, one folder per site section
  Resources/      asset catalog, Poppins fonts, translation tables (I18n/*.json), PrivacyInfo.xcprivacy
MotoHubTests/     unit tests: formatting, i18n, search variables, JSON mapping, GraphQL errors, JWT, paging, session
MotoHubUITests/   screenshot walk-through against the live backend
```

- Screens depend only on the repository protocols. `AppContainer` is the only place that creates concrete types.
- The UI text is written in Uzbek, and `"…".tr` translates it. The tables in `Resources/I18n` are generated from the Android app's `lib/i18n/strings_*.dart`.

## Run

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open MotoHub.xcodeproj
```

To run the app against a local backend, set the `API_BASE_URL` build setting, for example to `http://localhost:3007`. Plain http to localhost is allowed through `NSAllowsLocalNetworking`.

CI runs from `.github/workflows/`:

- `ios.yml` runs on every push: it generates the project, builds it and runs the unit tests on an iPhone simulator.
- `screenshots.yml` walks through the main screens against the live backend and uploads the screenshots as an artifact.

## Releasing to the App Store

1. Join the Apple Developer Program ($99/year).
2. In `project.yml`, set `DEVELOPMENT_TEAM` to your team ID, then run `xcodegen generate`.
3. In Xcode, choose **Product → Archive**, then **Distribute App → App Store Connect**. You can do the same without a Mac with Codemagic or a GitHub Actions workflow that has signing secrets.
4. In App Store Connect:
   - Privacy policy URL: https://motopresto.online/privacy
   - Account deletion is in the app under **Mening sahifam → Mening profilim → Hisobni o'chirish**.
   - Give the reviewer a demo login.

- Bundle ID: `online.motopresto.app`, the same as the Android package.
- The app icon is the same as the Android one.
- `ITSAppUsesNonExemptEncryption` is `NO`, because the app only uses HTTPS.
