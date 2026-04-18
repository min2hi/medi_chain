  # MediChain — Mobile Migration Strategy (Flutter)

This document outlines the systematic approach for building the MediChain mobile application, ensuring full feature parity with the web version while optimizing for mobile UX and maintaining backend compatibility.

## Phase 1: Codebase Analysis Summary

### Backend Architecture
- **Tech Stack**: Node.js, Express, Prisma, PostgreSQL.
- **Auth**: JWT-based (7d expiry default), stateless. No refresh token implemented.
- **Key Modules**:
  - **Auth**: Register, Login.
  - **Medical**: Profile, Records, Medicines, Appointments, Health Metrics.
  - **AI & Recommendation**: Chat, Consultation (Engine-based), Feedback, Sessions.
  - **Sharing**: Granular sharing with other users (Doctors/Family).
- **Data Format**: Standard JSON. Success/Failure wrapper.

### Frontend Web (Current)
- **Tech Stack**: Next.js (App Router), React, Tailwind CSS.
- **Routing**: File-based (auth, cai-dat, chia-se, ho-so, lich-hen, thuoc, tu-van).
- **State Management**: Mostly local state with `localStorage` for sync and custom events.
- **Service Layer**: Centralized [api.client.ts](file:///d:/StudioProjects/medi_chain/frontend/src/services/api.client.ts) using [fetch](file:///d:/StudioProjects/medi_chain/frontend/src/app/page.tsx#52-72).

---

## Phase 2: System Review & Evaluation

### Current Strengths
- **Clean API Contracts**: Well-defined endpoints for CRUD operations.
- **AI Integration**: Robust recommendation engine logic already separated in backend.
- **Sharing Model**: flexible sharing system using `X-Viewing-As` header.

### Mobile-Specific Challenges
- **Navigation**: Web uses a sidebar; Mobile needs Tabs or a Drawer.
- **Forms**: Complex medical forms need to be broken down into steps or better organized for small screens.
- **Data Visualization**: Health metric charts need a responsive mobile library (e.g., `fl_chart`).
- **Offline Access**: Essential for medical records; requires local DB (SQLite/Hive).

### Migration Risks
- **Token Security**: Moving from `localStorage` to `flutter_secure_storage`.
- **Session Persistence**: Default 7-day token is fine, but mobile users expect longer sessions or easier re-auth (Biometrics).

---

## Phase 3: Flutter Architecture Proposal

### 1. Project Structure (Layered Architecture)
```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── network/ (Dio configurations, Interceptors)
├── data/
│   ├── models/ (JSON serialization)
│   ├── repositories/ (Data fetching logic)
│   └── datasources/ (Local/Remote)
├── domain/ (Entities, UseCases - Optional for this scale)
├── logic/ (State Management: BLoC or Provider/Riverpod)
├── presentation/ (UI layer)
│   ├── screens/
│   ├── widgets/
│   └── routes/
└── main.dart
```

### 2. Tech Stack Recommendations
- **State Management**: `flutter_bloc` (Scalable) or `Provider` (Simpler). Given the complexity of medical data, **BLoC** is recommended.
- **Networking**: `Dio` (Better than http for interceptors/logging).
- **Local Storage**: `flutter_secure_storage` (Tokens) and `hive` or `sqflite` (Medical cache).
- **Navigation**: `go_router` or `AutoRoute`.

---

## Phase 4: Mapping Web → Mobile

| Web Screen | Mobile Equivalent | UX Changes | API Used |
| :--- | :--- | :--- | :--- |
| Home (Dashboard) | Home Screen (Tab 1) | Vertical scroll, Card-based summary. | `/user/dashboard` |
| Medical Records | Records List & Detail | Pull-to-refresh, Swipe-to-delete. | `/user/records` |
| AI Consultation | AI Chat / Consult | Chat-bubble UI, Sticky Input. | `/recommendation/consult` |
| Appointments | Calendar / List View | Date picker integration. | `/user/appointments` |
| Sharing | Sharing Manager | QR Code sharing (Proposed enhancement). | `/sharing` |
| Settings | Profile / Settings Tab | Native toggles, Biometric login toggle. | `/user/profile` |

---

## Phase 5: Implementation Roadmap

### Phase 1: Foundation (3-5 days)
- Setup Flutter project structure.
- Define Theme (Colors, Typography) matching MediChain branding.
- Base Networking layer with Dio + Auth Interceptor.

### Phase 2: Auth Module
- Login & Register screens.
- Token storage and Auto-login logic.

### Phase 3: Core Medical Modules
- Home Dashboard.
- Records & Health Metrics (List, Add, Edit).
- Medicine Tracking.

### Phase 4: Advanced Features
- AI Consultation (Chat interface).
- Sharing & Permissions.
- Notifications (Local reminders for medicine).

### Phase 5: Polish & UX
- Loading/Error states (Shimmer effect).
- Animations & Transitions.
- Basic Offline caching.
