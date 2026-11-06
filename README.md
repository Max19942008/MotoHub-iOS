# MotoHub for iOS

Native iOS app for **MotoHub**, a marketplace in Uzbekistan for motorcycles, spare parts and accessories. It is written in Swift and SwiftUI, needs iOS 17 or later, and its UI is in Uzbek.

It uses the same backend as the [website](https://github.com/Max19942008/Ignition) and the [Android app](https://github.com/Max19942008/MotoHub-App): the [MotoHub API](https://github.com/Max19942008/MotoHub), over GraphQL.

## Features

- **Motorcycles:** search, filters (brand, type, condition, region, price), sorting, infinite scroll, pull to refresh.
- **Spare parts and accessories:** one list for each category, each with its own filters.
- **Detail pages:** photo gallery, specs, description, seller card, one-tap call.
- **AI assistant:** ask in Uzbek, Russian or English. Answers come from MotoHub listings (RAG on the backend), with tappable listing cards.
- **Accounts:**
  - Log in and sign up with the same account as the website.
  - Tokens are kept in the Keychain and refreshed silently, with rotating refresh tokens.
  - You can delete your account inside the app, as App Store Review Guideline 5.1.1(v) requires.
- While the free Render backend is waking up (about 50 s), the app shows a wait message.
- Light and dark mode.

## Architecture

Clean architecture with one-way dependencies: **Presentation → Domain ← Data**. `App/` wires them together.

```
MotoHub/
  App/            entry point, composition root (AppContainer), tabs, navigation routes
  Domain/         entities, filters, repository protocols, AppError (no UIKit, no networking)
  Data/
    Network/      typed GraphQL client (GraphQLOperation<Variables, Response>), error translation
    Listings/     DTOs ↔ entities, GraphQLListingRepository
    Auth/         AuthSession actor (single-flight token refresh), Keychain TokenStore, JWT, auth repository
    Assistant/    GraphQLAssistantRepository
  Presentation/   @Observable view models + SwiftUI views
    Common/       PagedListViewModel, DetailViewModel, shared components, formatting
    Listings/  Assistant/  Profile/  Session/
  Resources/      asset catalog, PrivacyInfo.xcprivacy
MotoHubTests/     unit tests for formatting, DTO mapping, GraphQL errors, JWT, paging, session
```

- Screens depend only on the repository protocols. `AppContainer` is the only place that creates concrete types, so the tests swap in fakes.
- `AuthSession` is an actor. Refresh tokens are single-use, so concurrent requests that find an expired access token all wait on one refresh call.
- `PagedListViewModel` counts query generations, so a slow response for an old filter cannot overwrite the results of a newer one.

## Run

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open MotoHub.xcodeproj
```

To run the app against a local backend, set the `API_BASE_URL` build setting, for example to `http://localhost:3007`. Plain http to localhost is allowed through `NSAllowsLocalNetworking`.

CI is in `.github/workflows/ios.yml`. On every push it generates the project, builds it and runs the unit tests on an iPhone simulator.

## Releasing to the App Store

1. Join the Apple Developer Program ($99/year).
2. In `project.yml`, set `DEVELOPMENT_TEAM` to your team ID, then run `xcodegen generate`.
3. In Xcode, choose **Product → Archive**, then **Distribute App → App Store Connect**. You can do the same without a Mac with Codemagic or a GitHub Actions workflow that has signing secrets.
4. In App Store Connect:
   - Privacy policy URL: https://ignition-plum.vercel.app/privacy
   - Account deletion is in the app under Profil → Hisobni o‘chirish.
   - Give the reviewer a demo login.

- Bundle ID: `uz.motohub.app`
- The app icon is the same as the Android one.
- `ITSAppUsesNonExemptEncryption` is `NO`, because the app only uses HTTPS.
