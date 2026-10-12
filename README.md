# DWCRA Connect

> **Empowering Rural Women's Self-Help Groups (SHGs) through Digital Financial Inclusion, Transparent Accounting, Multilingual Voice-Assisted AI, and Offline-Resilient Technology.**

[![Production API Health](https://img.shields.io/badge/API--Health-200%20OK%20Live-brightgreen)](https://dwcra-connect-backend.onrender.com/api/health)
[![Flutter Build](https://img.shields.io/badge/Flutter-3.12%2B-blue)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Express%20MongoDB-green)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

---

## 📌 Executive Summary & Problem Statement

Development of Women and Children in Rural Areas (**DWCRA**) and Self-Help Group (**SHG**) networks represent a vital pillar of microfinance and socioeconomic empowerment across India. However, millions of rural women face severe structural barriers when managing group finances:
1. **Manual Paper Ledgers & Discrepancies**: Hand-written physical registers lead to lost records, calculation errors, and delays in tracking individual member loans and EMIs.
2. **Language & Literacy Barriers**: Traditional banking apps require complex English/text navigation, excluding semi-literate members who communicate primarily in local regional dialects (e.g. Telugu, Tenglish).
3. **Lack of Transparency**: Members often lack instant visibility into their exact loan principal, paid amounts, remaining balances, due dates, or government subsidy grants.
4. **Intermittent Rural Connectivity**: Poor cellular networks in rural areas cause traditional web/mobile portals to fail or display confusing zero-value states.

**DWCRA Connect** solves these challenges by delivering an end-to-end, production-tested mobile microfinance platform tailored specifically for rural SHG members and group leaders (Presidents and Secretaries).

---

## 🚀 Key System Features

### 1. 📊 Digital Financial Lifecycle & Statement Management
- **Full Loan-EMI Lifecycle**: Automatically reconciles Loan Principal, Monthly Installment Schedules, Due Dates, and Paid Balances.
- **Atomic In-App EMI Payments**: Offers an interactive payment confirmation workflow backed by Mongoose session transactions.
  > *Clarification: The in-app payment system executes authenticated, atomic database-confirmed transactions. It does not execute real-money bank/UPI transfers.*
- **Double-Payment Protection**: Server-side checks block duplicate payment attempts on already-paid EMIs (`HTTP 400`).
- **Paginated Transaction Statements**: Real-time statement history (`GET /api/transactions?page=1&limit=20`) enriched with EMI installment numbers and payment timestamps.

### 2. 🤖 Unified Multilingual AI & Voice Assistant
- **Dual Text & Voice Interface**: One shared AI assistant engine for both typed text and hands-free voice interaction.
- **Multilingual Support**: Supports queries in **English**, **Telugu (తెలుగు)**, and **Tenglish** (Telugu written in Roman script e.g., *"Naa loan entha undi?"*, *"Naa next EMI eppudu?"*).
- **Deterministic Database Grounding**: Personal financial answers are queried directly from MongoDB Atlas—eliminating AI financial hallucinations.
- **Contextually Relevant Follow-up Chips**: Displays 2–4 clickable action chips under assistant responses for fluid multi-turn conversation.

### 3. 🔔 Idempotent Smart Notification Engine
- **Automated EMI Reminders**: Evaluates unpaid EMIs against calendar dates in India Standard Time (`Asia/Kolkata`) for 7-day, 3-day, 1-day upcoming reminders, due-today alerts, and overdue warnings.
- **Duplicate Prevention**: Uses deterministic key indexing (`NOTIF-memberId-emiId-stage`) to prevent duplicate notification creation even if opened repeatedly.
- **Payment-Success Receipts**: Creates automatic transaction receipts upon confirmed EMI payments.

### 4. 🔒 Role-Based Access Control (RBAC) & Security
- **Strict Scope Isolation**: Normal members see ONLY their own personal account data (`memberId === req.user.userId`).
- **Group Analytics for Leaders**: Group-wide financial analytics (`totalMembers: 10`, `totalGroupPrincipal`, `totalGroupPaid`, `totalGroupRemaining`) accessible exclusively to authenticated Presidents and Secretaries (`groupId === req.user.groupId`).
- **Hardened API Infrastructure**: Protected by `helmet` security headers, Express rate-limiters (`express-rate-limit`), and parameter sanitization blocking MongoDB query injection ($ne, $gt).

### 5. ⚡ Offline-First Local Cache & Data Sync
- **User-Scoped Caching**: Caches account summaries, loans, EMIs, transactions, subsidies, and notifications locally via `CacheService`.
- **Safe Offline Read**: Displays last synchronized data with clear timestamp indicators (`"Last synced: 29/3/2026"`) when internet is unavailable.
- **Offline Payment Blocking**: Prevents offline payment attempts with a clear message: `"Internet connection is required to complete EMI payment."`
- **Logout Clearing**: Automatically purges active cached user data on logout to ensure zero data leakage between user sessions.

---

## 🛠️ System Architecture

```
+-----------------------------------------------------------------------+
|                         FLUTTER MOBILE CLIENT                         |
|  [ Dashboard | Loans | EMIs | Transactions | Chat/Voice | Offline Cache ] |
+-----------------------------------+-----------------------------------+
                                    |
                            HTTPS REST / JSON
                                    |
+-----------------------------------v-----------------------------------+
|                     NODE.JS / EXPRESS BACKEND API                     |
|  [ Helmet Headers | Rate Limiters | JWT Auth | RBAC | Controllers ]  |
+-----------------+-----------------+-----------------+-----------------+
                  |                 |                 |
                  v                 v                 v
     +--------------------+ +---------------+ +------------------+
     | financialService   | | chatService   | | groupSummary     |
     | (Atomic Sessions)  | | (AI Engine)   | | & accountSummary |
     +---------+----------+ +-------+-------+ +--------+---------+
               |                    |                  |
               +--------------------+------------------+
                                    |
                                    v
+-----------------------------------------------------------------------+
|                    MONGODB ATLAS DATABASE (dwcra_connect)             |
|    [ Users | Loans | EMIs | Transactions | Subsidies | Notifications ]  |
+-----------------------------------------------------------------------+
```

---

## ⚙️ Local Setup Instructions

### Prerequisites
- **Flutter SDK**: `>= 3.12.2`
- **Node.js**: `>= 18.x`
- **MongoDB**: MongoDB Atlas Cluster or local MongoDB instance

### 1. Backend Setup (`C:\dwcra_connect\backend`)
1. Navigate to the backend directory:
   ```bash
   cd C:\dwcra_connect\backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in `C:\dwcra_connect\backend\.env`:
   ```env
   PORT=5000
   NODE_ENV=development
   MONGO_URI=mongodb+srv://<USERNAME>:<PASSWORD>@<CLUSTER>.mongodb.net/dwcra_connect?retryWrites=true&w=majority
   JWT_SECRET=<YOUR_PRODUCTION_JWT_SECRET_PLACEHOLDER>
   OPENAI_API_KEY=<OPTIONAL_OPENAI_KEY_FOR_NON_FINANCIAL_AI_FALLBACK>
   CLIENT_ORIGIN=*
   ```
4. Start the backend server:
   ```bash
   npm start
   ```
   > *Server runs at `http://localhost:5000` (or `http://10.0.2.2:5000` inside Android Emulator).*

### 2. Frontend Setup (`C:\dwcra_connect`)
1. Navigate to the root directory:
   ```bash
   cd C:\dwcra_connect
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analyzer:
   ```bash
   flutter analyze
   ```
4. Run application in debug mode:
   ```bash
   flutter run
   ```

---

## 📦 Building Android Release APK

To build a standalone, optimized Android Release APK:

1. Clean previous build artifacts:
   ```bash
   flutter clean
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Execute release build:
   ```bash
   flutter build apk --release
   ```
4. Locate the generated APK at:
   ```
   C:\dwcra_connect\build\app\outputs\flutter-apk\app-release.apk
   ```

---

## 🧪 Testing Summary

- **Financial Integrity**: Verified across all 10 members of `GRP001` with **0 orphaned records**, **0 duplicate transaction IDs**, and 100% mathematical match between member records and group aggregations.
- **RBAC & Security**: 44/44 security test cases passed (Authentication, IDOR protection, payment validation, rate limiting, and prompt injection defense).
- **Production API Performance**: Live production endpoints on Render respond in **110 ms – 820 ms**.
- **Static Analysis**: `flutter analyze` completed with **0 errors**.

---

## ⚠️ Limitations & Future Enhancements

### Current Limitations
1. **In-App Payment Realism**: EMI payments execute as authenticated database-confirmed transactions. Real-money bank/UPI transfers via gateways (e.g. Razorpay/UPI APIs) are not integrated.
2. **Speech Recognition**: Speech-to-Text accuracy depends on device-native speech engines and background noise levels.

### Future Scope
- Integration with NPCI / UPI payment gateway sandbox APIs.
- Multi-group administrative portal for district-level DWCRA officers.
- Biometric authentication (fingerprint / face unlock) for fast offline logins.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
