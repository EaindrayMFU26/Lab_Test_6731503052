# AI Usage Report

## AI Tools Used

- GitHub Copilot in VS Code (model: GPT-5.3-Codex)
- Flutter and Firebase official CLI tools for project setup and deployment

## What AI Generated

AI assistance was used to generate and structure:
- Flutter project scaffolding workflow and setup steps
- App architecture and folder structure
- Screen implementations:
  - Home screen
  - Check-in screen
  - Finish class screen
- Data model (`ClassSession`) and serialization logic
- Local storage service (SharedPreferences CRUD flow)
- Firestore integration service and sync calls
- Firebase Hosting deployment configuration
- Documentation drafts for README and PRD support

## What Was Built or Adjusted Manually

The following engineering choices and refinements were applied through human-driven decisions during implementation:
- Requirement interpretation from incomplete exam brief
- Field naming and status workflow (`checkedIn`, `completed`)
- Validation rules and submit constraints (GPS, QR, required text fields)
- UX improvements for faster submission behavior
- Save flow optimization to prioritize local storage and make cloud sync non-blocking
- Final deployment verification and live URL confirmation

## Verification Performed

- Static checks with `flutter analyze` (project source)
- Web build validation with `flutter build web --release`
- Firebase Hosting deployment and live URL response verification
