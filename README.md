<div align="center">

<br/>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white" />
<img src="https://img.shields.io/badge/OneSignal-E54A4A?style=for-the-badge&logo=onesignal&logoColor=white" />

<br/><br/>

</div>

# TutorLink

A polished Flutter app that bridges the gap between **Parents**, **Tutors**, and **Children** — enabling real-time group chat with media sharing, assignment tracking with file attachments, progress monitoring, and instant push notifications, all in one unified platform.

---

## Features

**Authentication & Onboarding**
- Email/password registration with Firebase Authentication
- Email verification flow before accessing the app (auto-polls every 3s for verification status)
- Role-based sign-up: Parent, Tutor, or Student
- Parent sub-type selection (Father / Mother)
- First-time **avatar setup flow** — every role picks an illustrated profile picture right after verification, before reaching the home screen
- Forgot password via email reset link

**Custom Avatar System**
- 10 hand-picked illustrated avatars per role (Parent, Tutor, Student), shown in a 3-column picker grid
- Students additionally get a paired "second image" + accent color, used across progress cards and home screen for a playful, personalized look
- Rectangular avatar style (`RectAvatar`) used consistently across home, chat, profile, and assignment screens instead of plain circular avatars
- Changeable anytime from Profile → Change Profile Picture
- Updating a Tutor/Student avatar automatically propagates to all their existing links and group chats

**Role-Based Home Screens**
- **Parent** — time-of-day aware greeting (with a matching sun/moon illustration), children overview with live progress rings, active tutor count
- **Tutor** — dashboard with student count, pending review count, student list with per-student progress rings
- **Student** — overall progress card with gradient banner, subject breakdown, recent feedback from Tutors

**Parent–Tutor–Child Linking**
- Parents initiate links by entering Tutor email, subject, and one or more student emails
- Full validation: checks registration, correct role, correct subject, no duplicate links, no subject conflicts
- Multi-student link creation in a single form submission
- Auto-creates a group chat for each Tutor+subject pair on link creation

**Group Chat — now with media sharing**
- One group chat per Tutor × subject, shared by Tutor, student(s), and all linked parents
- Real-time messaging via Firestore streams
- **Send images and files (PDF, DOCX, TXT, ZIP) directly in chat**, uploaded to Cloudinary
- Image messages render as inline thumbnails (single image = large preview, multiple = grid) with a full-screen swipeable viewer
- File messages render as downloadable tiles with file-type icons; tapping downloads and opens the file on-device
- Multiple pending attachments can be queued and previewed before sending, with per-file upload progress and error states
- Sender labels showing role in brackets (e.g. "Ahmed (Father)")
- "Me" label for own messages; consecutive messages from same sender collapse the label
- Time-sorted chat list with `timeago` timestamps

**Assignments — now with attachments**
- Tutor creates assignments for one or multiple students at once (multi-select picker with Select All / Deselect All)
- Tutors can attach reference images/files to the assignment itself
- Students submit assignments with a text answer **and/or** attached images/files via bottom sheet
- Tutors review submissions: Approved / Needs Work, feedback text, optional marks
- Status badges: Pending · Submitted · Reviewed
- Overdue indicator (red date) for pending past-due assignments
- Tabbed views: All / Submitted / Reviewed (Tutor), Pending / Submitted / Reviewed (student)
- Parent sees all children's assignments in one unified, filterable list (by child, by status)

**Cloudinary File Storage**
- All chat and assignment/submission images & files are uploaded to Cloudinary via unsigned upload presets
- Automatic resource-type detection: images go to the `image` endpoint, documents (PDF/DOCX/TXT/ZIP) go to the `raw` endpoint
- Organized folder structure per use case (`tutorlink/chat/images`, `tutorlink/assignments/files`, `tutorlink/submissions/images`, etc.)
- Downloaded files are cached locally and opened with the native file viewer (`open_filex`)

**Push Notifications (OneSignal)**
- OneSignal external-ID login/logout tied to Firebase Auth session, so notifications follow the signed-in user across devices
- Server-side push triggered the moment a Tutor creates an assignment:
  - Student gets notified directly
  - All linked parents get notified with their child's name included
- Tapping a notification deep-links straight into the relevant `AssignmentDetailScreen`, even from a cold start
- Silent-fail design — if the push API call fails, the assignment is still created successfully

**Progress Tracking**
- Tutors update per-subject progress with four sliders: Homework Completion, Understanding, Participation, Improvement
- Live overall score preview while adjusting sliders
- Optional notes / feedback per update
- Upsert logic: updates existing record for same Tutor+child+subject
- Parents and students see subject breakdown cards with score bars and progress rings
- Tutor notes section with styled quote cards

**Profile**
- Shared profile header with rectangular avatar, "Change Profile Picture" shortcut, name, email, role badge
- Parent: linked children list, linked Tutors list, add-link sheet
- Tutor: linked student list with navigation to student progress
- Student: linked Tutors list
- Logout with custom confirmation dialog (icon + two-button layout)
- About TutorLink dialog

---

## Screenshots
### Log In & Sign Up
<table>
  <tr>
    <td align="center"><img src="app screenshots/log in sign up/2.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/log in sign up/1.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/log in sign up/3.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/log in sign up/4.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/log in sign up/5a.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/log in sign up/6.jpg" width="220"/></td>
  </tr>
</table>

---

### Parent
<table>
  <tr>
    <td align="center"><img src="app screenshots/parent/7.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/8.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/9.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/parent/10.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/11.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/12.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/parent/13a.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/14.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/15.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/parent/16.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/17.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/18.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/parent/19.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/parent/20.jpg" width="220"/><br/><b>Add New Student to an Existed Group</b></td>
    <td align="center"><img src="app screenshots/parent/21.jpg" width="220"/></td>
  </tr>
</table>

---

### Tutor
<table>
  <tr>
    <td align="center"><img src="app screenshots/tutor/22.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/23.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/24.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/tutor/25.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/26.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/27.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/tutor/28.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/29.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/30.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/tutor/31.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/32.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/33.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/tutor/34.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/tutor/35.jpg" width="220"/></td>
    <td></td>
  </tr>
</table>

---

### Student
<table>
  <tr>
    <td align="center"><img src="app screenshots/student/36.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/student/37.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/student/38.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/student/39.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/student/40.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/student/41.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/student/42.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/student/43.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/student/44.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/student/45.jpg" width="220"/></td>
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
| File / Media Storage | Cloudinary (unsigned uploads, image + raw endpoints) |
| Push Notifications | OneSignal (+ Firebase Messaging for platform delivery) |
| UI | Google Fonts (Nunito), percent_indicator, fl_chart, cached_network_image |
| File Handling | image_picker, file_picker, open_filex, path |
| Utilities | timeago, intl, uuid, http, http_parser |

---

## Architecture

```
lib/
├── main.dart                        # App entry, AuthWrapper, SplashScreen,
│                                    #   OneSignal notification-tap deep link
├── firebase_options.dart
├── models/
│   └── models.dart                  # AppUser, Child, TeacherChildLink,
│                                    #   GroupChat, Message, ChatAttachment,
│                                    #   Assignment, AssignmentAttachment,
│                                    #   Submission, ProgressUpdate
├── services/
│   ├── auth_service.dart            # Register, login, verify, logout, reset
│   │                                #   + OneSignal login/logout binding
│   ├── firestore_service.dart       # All Firestore reads/writes/streams
│   ├── cloudinary_service.dart      # Image/file upload to Cloudinary
│   └── notification_service.dart   # OneSignal init + assignment push helpers
├── utils/
│   ├── constants.dart               # AppConstants, enums, extensions
│   └── theme.dart                   # AppColors, AppTheme (Material 3)
├── widgets/
│   ├── widgets.dart                 # AppAvatar, ProgressRing, StatCard,
│   │                                #   SectionHeader, EmptyState,
│   │                                #   RoleBadge, StatusBadge, ScoreBar,
│   │                                #   AppLoading
│   └── attachment_widgets.dart      # PendingAttachment, AttachmentPickerSection,
│                                    #   AttachmentViewSection, ChatAttachmentViewSection,
│                                    #   FullScreenImageViewer, upload helpers
└── screens/
    ├── shell/
    │   └── main_shell.dart          # IndexedStack bottom nav shell
    ├── auth/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── verify_email_screen.dart
    │   └── setup_profile_picture_screen.dart  # Avatar picker + RectAvatar widget
    ├── home/
    │   └── home_screen.dart         # _ParentHome, _TeacherHome, _ChildHome
    ├── chat/
    │   ├── chats_screen.dart
    │   └── chat_room_screen.dart    # Text + image/file messaging
    ├── assignments/
    │   ├── assignments_screen.dart
    │   └── assignment_detail_screen.dart  # Submit/review with attachments
    ├── progress/
    │   └── student_progress_screen.dart
    └── profile/
        └── profile_screen.dart
```

**Auth & Onboarding Flow**

```
App Launch
    └── FirebaseAuth.authStateChanges()
            ├── No user          →  LoginScreen
            ├── Not verified     →  VerifyEmailScreen (polls every 3s)
            └── Verified
                    └── Load AppUser from Firestore
                            ├── No avatar set   →  SetupProfilePictureScreen
                            └── Avatar set      →  MainShell
```

**Linking & Chat Creation**

```
Parent submits link form
    └── Validate tutor email  (role = tutor)
    └── Validate student email  (role = child, same parent)
    └── Check duplicate link
    └── Check subject conflict  (one tutor per subject)
    └── Create teacherChildLink doc
    └── Update children/{childId}.tutorIds + parentIds
    └── Upsert GroupChat (tutor + subject)  →  add all memberIds
```

**Attachment Upload Flow (Chat / Assignment / Submission)**

```
User picks image or file
    └── Stored as PendingAttachment (local, not yet uploaded)
    └── On send/submit:
            └── CloudinaryService.uploadFile()
                    ├── Detect resource type (image vs raw)
                    ├── Auto-route to correct folder
                    └── Return secure_url + filename + type
            └── Wrapped into ChatAttachment / AssignmentAttachment
            └── Saved alongside the message / assignment / submission doc
```

**Assignment Notification Flow**

```
Tutor creates assignment
    └── Assignment doc written to Firestore
    └── NotificationService.sendAssignmentNotificationToChild()
    └── Fetch linked parentIds from children/{childId}
    └── NotificationService.sendAssignmentNotificationToParents()
            └── POST to OneSignal REST API (target_channel: push)
            └── data: { assignmentId } → used for deep link on tap
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled
- A [Cloudinary](https://cloudinary.com) account with an **unsigned upload preset**
- A [OneSignal](https://onesignal.com) app configured for push notifications

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

4. **Cloudinary setup**

   - Create a Cloudinary account and note your **Cloud Name**
   - Create an **unsigned upload preset**
   - Set `_cloudName` and `_uploadPreset` in `lib/services/cloudinary_service.dart`

5. **OneSignal setup**

   - Create a OneSignal app and link it to your Firebase project for Android push delivery
   - Set `_appId` and `_restApiKey` in `lib/services/notification_service.dart`

6. **Run the app**

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
# Firebase
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_storage: ^12.3.2
firebase_messaging: ^15.1.3

# Push notifications
onesignal_flutter: ^5.6.0

# UI
google_fonts: ^6.2.1
percent_indicator: ^4.2.3
cached_network_image: ^3.4.1
fl_chart: ^0.69.0
timeago: ^3.7.0
intl: ^0.20.2
uuid: ^4.5.1

# File & image handling
image_picker: ^1.2.2
file_picker: ^8.0.0
open_filex: ^4.7.0
path: ^1.9.1
path_provider: ^2.1.4

# Network
http: ^1.5.0
http_parser: ^4.1.2

# Utils
shared_preferences: ^2.3.2
permission_handler: ^11.3.1
url_launcher: ^6.3.0
```

---

## Security Notes

- Firebase credentials (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are **not included** in this repository. You must configure your own Firebase project.
- Cloudinary `_cloudName` and `_uploadPreset` and OneSignal `_appId` / `_restApiKey` in this repo are placeholders — replace with your own before running.
- The OneSignal REST API key is currently called directly from the client for simplicity. For production, move push-sending behind a Cloud Function so the REST API key is never bundled in the app.
- Firestore rules above are suitable for development. For production, tighten them to validate ownership per document (e.g. only linked members can read a group chat).

---

## License

This project is open-source and available under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ and Flutter by **[TanvirAhmedCSE](https://github.com/TanvirAhmedCSE)**

*If you find this project useful, please give it a ⭐ on GitHub!*

</div>
