# DWCRA CONNECT TECHNICAL ARCHITECTURE SPECIFICATION

---

## 1. HIGH-LEVEL SYSTEM ARCHITECTURE

DWCRA Connect is designed as a multi-tier microfinance platform comprising a **Flutter Mobile Application**, a **Node.js/Express REST API Service**, and a **MongoDB Atlas Document Database**.

```mermaid
graph TD
    subgraph Client Tier [Flutter Mobile Application]
        UI[Flutter Mobile UI / Dashboards]
        State[Riverpod State Management]
        Cache[CacheService Local SharedPreferences]
        VUI[Voice UI: Speech-To-Text / Text-To-Speech]
        HTTPClient[ApiService HTTPS Client]
    end

    subgraph API Tier [Node.js / Express Backend Engine]
        Security[Helmet Security Headers / Express Rate Limiters]
        JWTAuth[JWT Middleware / Auth Controller]
        FinancialService[financialService: Atomic Mongoose Sessions]
        ChatService[chatService: Deterministic Multilingual AI Engine]
        GroupSummary[groupSummaryService: Aggregated Leader Analytics]
        NotificationService[notificationService: Idempotent Reminders]
    end

    subgraph Data Tier [MongoDB Atlas Cloud Database]
        Users[(Users Collection)]
        Loans[(Loans Collection)]
        EMIs[(EMIs Collection)]
        Transactions[(Transactions Collection)]
        Subsidies[(Subsidies Collection)]
        Notifications[(Notifications Collection)]
    end

    UI --> State
    UI --> VUI
    State --> Cache
    State --> HTTPClient
    HTTPClient -->|HTTPS REST / JWT| Security
    Security --> JWTAuth
    JWTAuth --> FinancialService
    JWTAuth --> ChatService
    JWTAuth --> GroupSummary
    JWTAuth --> NotificationService

    FinancialService -->|Atomic Session Tx| Loans
    FinancialService -->|Atomic Session Tx| EMIs
    FinancialService -->|Atomic Session Tx| Transactions
    ChatService -->|Read Queries| Users
    ChatService -->|Read Queries| Loans
    ChatService -->|Read Queries| EMIs
    GroupSummary -->|Read Aggregations| Users
    GroupSummary -->|Read Aggregations| Loans
    NotificationService -->|Idempotent Index Write| Notifications
```

---

## 2. COMPONENT DATA FLOWS

### 2.1 Atomic EMI Payment Sequence
```mermaid
sequenceDiagram
    autonumber
    actor Member as Member (Mobile Client)
    participant UI as EmiDetailsScreen
    participant API as Express API (/api/emis/pay)
    participant Auth as JWT Auth Middleware
    participant Service as financialService (Mongoose Session)
    participant DB as MongoDB Atlas

    Member->>UI: Tap "Pay EMI Now"
    UI->>UI: Check Internet Connection
    alt Is Offline
        UI-->>Member: Display "Internet connection required to complete EMI payment"
    else Is Online
        UI->>API: POST /api/emis/pay { emiId, amount }
        API->>Auth: Verify JWT Token Signature
        Auth-->>API: Valid Token Claims (userId, groupId)
        API->>Service: processEmiPayment(memberId, emiId, amount)
        Service->>DB: Start Mongoose Session Transaction
        Service->>DB: Verify EMI Ownership & Unpaid Status
        alt Status != 'pending' / 'overdue' OR Amount Mismatch
            Service->>DB: Abort Transaction
            Service-->>API: Reject Payment (HTTP 400/403)
            API-->>UI: Payment Failure Error Sheet
        else Payment Valid
            Service->>DB: Update EMI.status = 'paid', paidDate = now
            Service->>DB: Insert Transaction Record (type: 'loan_payment')
            Service->>DB: Recalculate Loan Remaining Balance
            Service->>DB: Insert Payment-Success Notification
            Service->>DB: Commit Session Transaction
            Service-->>API: Payment Confirmed Success Response
            API-->>UI: HTTP 200 OK
            UI->>UI: Update Local Cache & Refresh Providers
            UI-->>Member: Display Payment Confirmed Sheet
        end
    end
```

---

### 2.2 Multilingual Voice & AI Assistant Flow
```mermaid
sequenceDiagram
    autonumber
    actor User as Member / Leader
    participant Mic as STT / Keyboard Input
    participant ChatUI as ChatScreen
    participant Engine as chatService.js
    participant DB as MongoDB Atlas
    participant TTS as flutter_tts Synthesizer

    User->>Mic: Speak query ("Naa loan entha undi?")
    Mic->>ChatUI: Transcribe text ("Naa loan entha undi?")
    ChatUI->>Engine: POST /api/chat { message, inputMode: 'voice' }
    Engine->>Engine: Verify JWT Auth Claims (userId, role, groupId)
    Engine->>Engine: detectIntent() -> 'personal_loan_remaining'
    Engine->>DB: Query Loans for memberId
    DB-->>Engine: Return Principal (₹50,000) & Remaining (₹48,456.15)
    Engine->>Engine: constructResponse() in Tenglish
    Engine-->>ChatUI: Response Text + Action Chips
    alt InputMode == 'voice'
        ChatUI->>TTS: speak(replyText)
        TTS-->>User: Play Spoken Response Aloud
    end
    ChatUI-->>User: Render Assistant Bubble + Suggestion Chips
```

---

## 3. SECURITY & CACHE DESIGN

### 3.1 Rate Limiting Topology
- **Auth Limiter**: Applied to `/api/auth/` $\rightarrow$ Max 20 requests per 15 minutes per IP.
- **Sensitive Action Limiter**: Applied to `/api/emis/pay` & `/api/chat` $\rightarrow$ Max 60 requests per 15 minutes per IP.
- **General API Limiter**: Applied to `/api/` $\rightarrow$ Max 300 requests per 15 minutes per IP.

### 3.2 User-Scoped Local Cache Key Structure
- Account Summary: `cache_${userId}_account_summary`
- Loans List: `cache_${userId}_loans_${memberId}`
- EMI Schedule: `cache_${userId}_emis_${memberId}`
- Transaction Statement: `cache_${userId}_txs_${memberId}`
- Notification List: `cache_${userId}_notifications`
- Group Summary (Leaders Only): `cache_${userId}_group_members_summary_${groupId}`
