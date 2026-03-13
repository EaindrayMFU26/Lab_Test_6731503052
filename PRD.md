# Product Requirement Document (PRD)
## Smart Class Check-In and Learning Reflection App

Course: 1305216 Mobile Application Development  
Date: March 13, 2026

---

## 1. Problem Statement

Class attendance needs stronger evidence than manual sign-in, and teachers also need lightweight learning reflection data. The app must prove presence and participation using:

- GPS location
- QR code scan
- Pre-class and post-class reflection

The system must support a clean lifecycle from check-in to completion on the same class session record.

---

## 2. Target User

| Role | Description |
|------|-------------|
| Student | Primary user. Performs check-in before class and class completion after class. |
| Instructor (future) | Reviews data in Firestore or a future dashboard. |

MVP scope: Student-facing flow only, no authentication screen.

---

## 3. Feature List

### Core MVP Features

- Home screen with status-aware actions
- Check In screen with strict evidence capture
- Finish Class screen that updates the active session
- Local storage persistence using SharedPreferences
- Firebase Firestore integration for cloud backup
- Session history list on Home

### Validation and Lifecycle Rules

- Only one active session at a time
- Check-in must be completed before finish
- Finish updates the same active record (not a new record)

---

## 4. User Flow

1. User opens Home.
2. User taps Check In.
3. User confirms or enters Student ID.
4. User gets GPS location.
5. User scans class QR.
6. User fills previous topic.
7. User fills expected topic.
8. User selects mood (1 to 5).
9. User taps submit.
10. App saves one active session locally and starts cloud sync in background.
11. User later taps Finish Class.
12. App loads current active session.
13. User gets GPS again.
14. User scans QR again.
15. User fills what was learned and feedback.
16. User taps finish.
17. App updates same session with finish evidence and status completed.

---

## 5. Data Fields

### ClassSession Model

| Field | Type | Required | Description |
|------|------|----------|-------------|
| id | String | Yes | Unique session id |
| studentId | String | Yes | Student identifier |
| checkInTime | DateTime | Yes | Check-in timestamp |
| checkInLat | double | Yes | Check-in latitude |
| checkInLng | double | Yes | Check-in longitude |
| checkInQr | String | Yes | Raw QR text at check-in |
| previousTopic | String | Yes | Topic from previous class |
| expectedTopic | String | Yes | Expected topic today |
| mood | int (1-5) | Yes | Mood before class |
| status | enum | Yes | checkedIn or completed |
| finishTime | DateTime? | No | Finish timestamp |
| finishLat | double? | No | Finish latitude |
| finishLng | double? | No | Finish longitude |
| finishQr | String? | No | Raw QR text at finish |
| learnedToday | String? | No | Learning reflection |
| feedback | String? | No | Feedback text |

### Additional Local Preference Field

| Field | Type | Description |
|------|------|-------------|
| lastStudentId | String | Last used Student ID for auto-fill |

---

## 6. Validation Rules

### Check In Submit Requirements

- No active session exists
- Student ID is not empty
- GPS is captured
- QR is scanned
- Previous topic is filled
- Expected topic is filled
- Mood is selected

### Finish Class Submit Requirements

- Active session exists
- GPS is captured
- QR is scanned
- Learned today is filled
- Feedback is filled

---

## 7. Tech Stack

| Layer | Technology | Purpose |
|------|------------|---------|
| UI | Flutter (Dart) | Cross-platform mobile/web app |
| GPS | geolocator | Capture location evidence |
| QR scanner | mobile_scanner | Read class QR values |
| Local storage | shared_preferences | MVP persistence and last student id |
| Cloud | firebase_core + cloud_firestore | Cloud sync and storage |
| Deployment | Firebase Hosting | Publish web build |

---

## 8. Storage and Sync Strategy

- Local storage is the source of truth for MVP reliability.
- Firestore sync is best-effort and non-blocking.
- Submit returns user to Home immediately after local save.
- Slow network does not block lifecycle completion.

---

## 9. UI and Interaction Decisions

- Home buttons are state-aware:
    - No active session: Check In enabled, Finish Class disabled
    - Active session exists: Check In disabled, Finish Class enabled
- Timestamp evidence is visible on forms:
    - Check-in time preview on Check In screen
    - Finish-time note on Finish screen
- GPS and QR values are shown clearly as attendance evidence.

---

## 10. Deployment Notes

- Firebase project: smartclass-e607d
- Hosting URL: https://smartclass-e607d.web.app
- Source repository: https://github.com/EaindrayMFU26/Lab_Test_6731503052
