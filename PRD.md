# Product Requirement Document (PRD)
## Smart Class Check-in & Learning Reflection App

**Course:** 1305216 Mobile Application Development  
**Date:** March 13, 2026  

---

## 1. Problem Statement

Universities struggle to verify that students are physically present in class and actively engaged in learning. Manual attendance sheets are time-consuming and easily falsified. There is no structured way to capture students' pre-class expectations or post-class reflections, which are valuable for both instructors and students.

This app solves three problems:
1. **Attendance fraud** — GPS location + QR code together make it hard to fake presence.
2. **Engagement tracking** — mood scores and reflection text give instructors insight into class quality.
3. **Learning continuity** — asking students to recall the previous topic reinforces retention.

---

## 2. Target User

| Role | Description |
|------|-------------|
| **Student** | Primary user. Checks in at the start of class and checks out at the end. Fills in reflection fields. |
| **Instructor** *(future scope)* | Reviews attendance and reflection data via Firestore console or a future admin panel. |

**MVP scope:** Student-facing only. No instructor login in this version.

---

## 3. Feature List

### Must Have (MVP)
- [ ] **Check-in screen** — records GPS location, timestamp, and QR scan
- [ ] **Pre-class reflection form** — previous topic, expected topic, mood (1–5)
- [ ] **Finish class screen** — records GPS location and QR scan again
- [ ] **Post-class reflection form** — what was learned, feedback, mood (1–5)
- [ ] **Local storage** — all data persisted on-device via SharedPreferences
- [ ] **Firestore sync** — data backed up to Firebase cloud on each save

### Nice to Have (Post-MVP)
- [ ] Session history list screen
- [ ] Instructor dashboard
- [ ] Login / authentication
- [ ] Offline queue and sync when network returns

---

## 4. User Flow

```
App Launch
    │
    ▼
Home Screen
    ├──► [Check In to Class]
    │         │
    │         ▼
    │    Check-In Screen
    │         ├── Enter Student ID
    │         ├── Tap "Get GPS"  →  records lat/lng
    │         ├── Tap "Scan QR"  →  scans class QR code
    │         ├── Fill: Previous Topic
    │         ├── Fill: Expected Topic Today
    │         ├── Set Mood (slider 1–5)
    │         └── Tap "Submit Check-In"
    │                   │
    │                   ▼
    │            Save to SharedPreferences
    │            Sync to Firestore
    │                   │
    │                   └──► Home Screen
    │
    └──► [Finish Class]
              │
              ▼
         Finish Class Screen
              ├── Tap "Get GPS"  →  records lat/lng
              ├── Tap "Scan QR"  →  scans class QR code again
              ├── Fill: What I Learned Today
              ├── Fill: Feedback for Instructor
              ├── Set Mood (slider 1–5)
              └── Tap "Finish Class"
                        │
                        ▼
                 Update latest active session
                 Sync to Firestore
                        │
                        └──► Home Screen
```

---

## 5. Data Fields

### ClassSession model

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | ✅ | Unique ID (epoch milliseconds) |
| `studentId` | String | ✅ | Student manually enters their ID |
| `latitude` | double | ✅ | GPS latitude at check-in |
| `longitude` | double | ✅ | GPS longitude at check-in |
| `checkInTime` | DateTime | ✅ | Timestamp when check-in was submitted |
| `qrCode` | String | ✅ | Raw text value from QR scan |
| `previousTopic` | String | ✅ | Topic covered in the previous class |
| `expectedTopic` | String | ✅ | Topic student expects to learn today |
| `moodBefore` | int (1–5) | ✅ | Mood score before class |
| `checkOutTime` | DateTime | ❌ | Timestamp when finish-class was submitted |
| `learnedToday` | String | ❌ | Short text: what was learned |
| `feedback` | String | ❌ | Feedback about class or instructor |
| `moodAfter` | int (1–5) | ❌ | Mood score after class |

### Mood Scale

| Score | Label |
|-------|-------|
| 1 | 😡 Very Negative |
| 2 | 🙁 Negative |
| 3 | 😐 Neutral |
| 4 | 🙂 Positive |
| 5 | 😄 Very Positive |

---

## 6. Tech Stack

| Layer | Technology | Reason |
|-------|-----------|--------|
| UI framework | Flutter 3.x (Dart) | Cross-platform, required by course |
| GPS / location | `geolocator` | Cross-platform geolocation with permission handling |
| QR scanning | `mobile_scanner` | Camera-based QR/barcode scanning |
| Local storage | `shared_preferences` | Simple key-value store, fast for MVP |
| Database (optional) | `sqflite` | SQLite for structured queries if needed post-MVP |
| Cloud storage | `cloud_firestore` | Real-time NoSQL, easy Firebase integration |
| Firebase init | `firebase_core` | Required base package for all Firebase services |
| Hosting | Firebase Hosting | Deploys Flutter web build for Part 4 |

---

## 7. Design Assumptions & Engineering Decisions

These assumptions were made to fill gaps in the draft requirements:

1. **One active session per student at a time** — a student cannot check in twice without finishing the first session. The latest unclosed session is used when finishing class.
2. **QR code stores raw text** — the app stores whatever text is encoded in the QR code without parsing. The instructor is responsible for encoding a meaningful class identifier.
3. **Mood is an integer 1–5** — represented as a slider in the UI, stored as an integer in both local storage and Firestore.
4. **Check-in must happen before finish** — the finish-class screen looks up the latest session with no `checkOutTime`. If none exists, an error is shown.
5. **Local storage is the source of truth for MVP** — SharedPreferences stores all sessions on-device. Firestore is a cloud backup and is optional for the app to function.
6. **Firestore sync is best-effort** — if Firestore write fails, an error is shown but local data is preserved.
7. **No login screen for MVP** — the student manually types their ID. Authentication is deferred to a future version.
8. **Location is recorded at submission time** — GPS is fetched when the user taps "Get GPS", not automatically in the background.
