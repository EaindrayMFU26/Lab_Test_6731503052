# AI Usage Report

## 1. AI Tools Used

- GitHub Copilot in VS Code (model: GPT-5.3-Codex)
- Flutter CLI
- Firebase CLI
- FlutterFire CLI

## 2. What AI Helped Generate

AI assistance was used for:

- Project scaffolding and package setup
- Suggested folder structure and service layering
- Initial implementation of:
  - Home screen
  - Check In screen
  - Finish Class screen
- ClassSession model and map/json conversion methods
- SharedPreferences storage flow (save, list, update, latest open session)
- Firestore service wiring and Firebase Hosting setup
- Documentation drafts for README and PRD

## 3. What Was Decided and Refined by Developer Judgment

The following were refined through manual direction and iteration:

- Final product flow and lifecycle logic:
  - one active session at a time
  - check in first, finish later on same record
- Stronger validation behavior and disabled-submit conditions
- Timestamp evidence visibility on form screens
- State-aware Home button behavior (Check In vs Finish availability)
- Session history improvements (check-in time, finish time, summary details)
- Non-blocking cloud sync so local save is instant
- UI restyling to MFU-inspired red, beige, and neutral palette

## 4. Responsibility and Review

- AI output was reviewed, edited, and tested before finalizing.
- Business rules and final behavior were accepted only after matching the exam requirements.

## 5. Verification Performed

- Static analysis on app source: flutter analyze lib
- Web production build: flutter build web --release
- Firebase Hosting deploy verification (HTTP 200)

## 6. Final Delivery References

- Firebase URL: https://smartclass-e607d.web.app
- GitHub repository: https://github.com/EaindrayMFU26/Lab_Test_6731503052
