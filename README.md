<div align="center">

<br/>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Hive-FFB300?style=for-the-badge&logo=hive&logoColor=white" />

<br/><br/>

</div>

# TutorLink 

A polished Flutter app that bridges the gap between **Parents**, **Tutors**, and **Children** — enabling real-time group chat, assignment tracking, progress monitoring, and seamless academic collaboration in one unified platform.

---

## Features

**Authentication & Onboarding**
- Email/password registration with Firebase Authentication
- Email verification flow before accessing the app
- Role-based sign-up: Parent, Tutor, or Student
- Parent sub-type selection (Father / Mother)
- Secure session restoration via Hive cache
- Forgot password via email reset link

**Role-Based Home Screens**
- **Parent** — greeting with time-of-day awareness, children overview with live progress rings, active tutor count
- **Tutor** — dashboard with student count, pending review count, student list with per-student progress rings
- **Student** — overall progress card with gradient banner, subject breakdown, recent feedback from Tutors

**Parent–Tutor–Student Linking**
- Parents initiate links by entering Tutor email, subject, and one or more student emails
- Full validation: checks registration, correct role, correct subject, no duplicate links, no subject conflicts
- Multi-student link creation in a single form submission
- Auto-creates a group chat for each Tutor+subject pair on link creation

**Group Chat**
- One group chat per Tutor × subject, shared by Tutor, student(s), and all linked parents
- Real-time messaging via Firestore streams
- Sender labels showing role in brackets (e.g. "Ahmed (Father)")
- "Me" label for own messages; consecutive messages from same sender collapse the label
- Time-sorted chat list with `timeago` timestamps

**Assignments**
- Tutor creates assignments for one or multiple students at once (multi-select picker with Select All / Deselect All)
- Students submit assignments with a text answer via bottom sheet
- Tutors review submissions: Approved / Needs Work, feedback text, optional marks
- Status badges: Pending · Submitted · Reviewed
- Overdue indicator (red date) for pending past-due assignments
- Tabbed views: All / Submitted / Reviewed (Tutor), Pending / Submitted / Reviewed (student)
- Parent sees all children's assignments in one unified list

**Progress Tracking**
- Tutors update per-subject progress with four sliders: Homework Completion, Understanding, Participation, Improvement
- Live overall score preview while adjusting sliders
- Optional notes / feedback per update
- Upsert logic: updates existing record for same Tutor+child+subject
- Parents and students see subject breakdown cards with score bars and progress rings
- Tutor notes section with styled quote cards

**Profile**
- Shared profile header with avatar (initials fallback), name, email, role badge
- Parent: linked children list, linked Tutors list, add-link sheet
- Tutor: linked student list with navigation to student progress
- Student: linked Tutors list
- Logout with custom confirmation dialog (icon + two-button layout)
- About TutorLink dialog

**Notifications (Local)**
- Four notification channels: Messages, Assignments, Progress Updates (via `awesome_notifications`)
- Helpers for: new message, new assignment, submission reviewed, progress updated

---

## Screenshots

### Sign Up & Email Verification

<table>
  <tr>
    <td align="center"><img src="app screenshots/1 sign up and email verification/1.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/1 sign up and email verification/2.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/1 sign up and email verification/3.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/1 sign up and email verification/4.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

### Parent

<table>
  <tr>
    <td align="center"><img src="app screenshots/2 parent/5.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/6.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/7.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/2 parent/8.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/9.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/10.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/2 parent/11.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/12.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/13.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/2 parent/14.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/15.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/16.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/2 parent/17.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/18.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 parent/19.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/2 parent/20.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

### Teacher 1

<table>
  <tr>
    <td align="center"><img src="app screenshots/3 teacher1/21.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/22.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/23.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/3 teacher1/24.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/25.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/26.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/3 teacher1/27.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/28.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/29.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/3 teacher1/30.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/31.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 teacher1/32.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/3 teacher1/33.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

### Teacher 2

<table>
  <tr>
    <td align="center"><img src="app screenshots/4 teacher2/34.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4 teacher2/35.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4 teacher2/36.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/4 teacher2/37.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

### Child 1

<table>
  <tr>
    <td align="center"><img src="app screenshots/5 student1/38.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 student1/39.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 student1/40.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/5 student1/41.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 student1/42.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 student1/43.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/5 student1/44.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 student1/45.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 student1/46.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/5 student1/47.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

### Child 2

<table>
  <tr>
    <td align="center"><img src="app screenshots/6 student2/48.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/6 student2/49.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/6 student2/50.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/6 student2/51.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/6 student2/52.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/6 student2/53.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/6 student2/54.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Local Storage | Hive (hive_flutter) |
| UI | Google Fonts (Nunito), percent_indicator, fl_chart |
| Notifications | awesome_notifications |
| Utilities | timeago, intl, uuid, cached_network_image |

---

## Architecture

```
lib/
├── main.dart                        # App entry, AuthWrapper, SplashScreen
├── firebase_options.dart
├── models/
│   └── models.dart                  # AppUser, Child, TeacherChildLink,
│                                    #   GroupChat, Message, Assignment,
│                                    #   Submission, ProgressUpdate
├── services/
│   ├── auth_service.dart            # Register, login, verify, logout, reset
│   ├── firestore_service.dart       # All Firestore reads/writes/streams
│   ├── hive_service.dart            # Local cache: user, assignments, chats
│   └── notification_service.dart   # awesome_notifications setup & helpers
├── utils/
│   ├── constants.dart               # AppConstants, enums, extensions
│   └── theme.dart                   # AppColors, AppTheme (Material 3)
├── widgets/
│   └── widgets.dart                 # AppAvatar, ProgressRing, StatCard,
│                                    #   SectionHeader, EmptyState,
│                                    #   RoleBadge, StatusBadge, ScoreBar,
│                                    #   AppLoading
└── screens/
    ├── shell/
    │   └── main_shell.dart          # IndexedStack bottom nav shell
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── verify_email_screen.dart
    ├── home/
    │   └── home_screen.dart         # _ParentHome, _TeacherHome, _ChildHome
    ├── chat/
    │   ├── chats_screen.dart
    │   └── chat_room_screen.dart
    ├── assignments/
    │   ├── assignments_screen.dart
    │   └── assignment_detail_screen.dart
    ├── progress/
    │   └── student_progress_screen.dart
    └── profile/
        └── profile_screen.dart
```

**Auth Flow**

```
App Launch
    └── FirebaseAuth.authStateChanges()
            ├── No user          →  LoginScreen
            ├── Not verified     →  VerifyEmailScreen (polls every 3s)
            └── Verified
                    ├── Hive cache hit  →  MainShell (instant)
                    └── Cache miss      →  Firestore fetch  →  MainShell
```

**Linking & Chat Creation**

```
Parent submits link form
    └── Validate tutor email  (role = tutor)
    └── Validate student email  (role = child, same parent)
    └── Check duplicate link
    └── Check subject conflict  (one tutor per subject)
    └── Create tutorChildLink doc
    └── Update children/{childId}.tutorIds + parentIds
    └── Upsert GroupChat (tutor + subject)  →  add all memberIds
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/TanvirAhmedCSE/tutorlink-parent-tutor-child-connectivity-platform.git
cd tutorlink-parent-tutor-child-connectivity-platform
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Firebase setup**

   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Email/Password** authentication
   - Enable **Cloud Firestore**
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) and place them in the correct platform directories
   - Run `flutterfire configure` or add your own `firebase_options.dart`

4. **Run the app**

```bash
flutter run
```

---

## Firestore Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    match /children/{childId} {
      allow read, write: if request.auth != null;
    }

    match /teacher_child_links/{linkId} {
      allow read, write: if request.auth != null;
    }

    match /group_chats/{chatId} {
      allow read, write: if request.auth != null;
      match /messages/{msgId} {
        allow read, write: if request.auth != null;
      }
    }

    match /assignments/{id}      { allow read, write: if request.auth != null; }
    match /submissions/{id}      { allow read, write: if request.auth != null; }
    match /progress_updates/{id} { allow read, write: if request.auth != null; }
  }
}
```

---

## Key Dependencies

```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
hive: ^2.2.3
hive_flutter: ^1.1.0
google_fonts: ^6.2.1
percent_indicator: ^4.2.3
awesome_notifications: ^0.11.0
timeago: ^3.7.0
intl: ^0.20.2
cached_network_image: ^3.4.1
fl_chart: ^0.69.0
```

---


## Security Notes

- Firebase credentials (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are **not included** in this repository. You must configure your own Firebase project.
- Firestore rules above are suitable for development. For production, tighten them to validate ownership per document (e.g. only linked members can read a group chat).

---

## License

This project is open-source and available under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ and Flutter by **[TanvirAhmedCSE](https://github.com/TanvirAhmedCSE)**

*If you find this project useful, please give it a ⭐ on GitHub!*

</div>
