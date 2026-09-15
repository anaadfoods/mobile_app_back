# Anaad AI Chat & Health Observation Module

The Anaad AI Chat feature provides a mobile-first, conversational AI assistant for organic food product recommendations, meal plans (Thali), active order tracking, Ayurvedic health observations, and privacy controls.

## Architecture

This module follows **Clean Architecture** conventions with Cubit state management:

```
lib/features/chat/
├── data/
│   ├── datasources/        # ChatRemoteDataSource (Dio HTTP + SSE Stream Client)
│   ├── models/             # ChatResponseModel (Defensive JSON mapping)
│   └── repositories/       # ChatRepositoryImpl
├── domain/
│   ├── entities/           # ChatMessageEntity, ChatResponseEntity, HealthObservation, ActionButton
│   ├── repositories/       # ChatRepository (Abstract interface)
│   └── usecases/           # SendMessage, StreamMessage, ConfirmAction, SaveHealthObservation, DeleteMemory, etc.
└── presentation/
    ├── cubit/              # ChatCubit & ChatState
    ├── screens/            # ChatScreen & HealthProfileScreen
    └── widgets/            # ChatInputBar, ChatMessageBubble, HealthObservationCardWidget, ThaliCardWidget, etc.
```

## Key Features & Protocols

### 1. Server-Sent Events (SSE) Streaming & Final Payload
- Real-time responses are streamed via `/api/v1/agent/chat/stream`.
- Events parsed: `stage`, `token`, `final_payload`, `done`, `error`.
- When `final_payload` is received, the temporary streamed message is replaced with the structured entity containing typed card data.

### 2. Safe Health Observation Consent Flow
- When the AI detects a user-reported food-symptom association (e.g. Kurkure and fever), it returns a `health_observation` object.
- The UI presents a **Health Observation Consent Card**:
  - Non-alarming, neutral design (no red/scare colors).
  - Explicit warning: *"User-reported, not medically confirmed"*.
  - Neutral disclaimers — no medical diagnosis or prescription.
  - Action buttons: **Save observation** (`save_health_observation=true`) or **Don't save** (dismissed locally).
  - Text link: **View warning signs** (opens non-alarming safety bottom sheet).

### 3. Cryptographic Nonce Confirmation Flow
- For side-effecting actions (e.g. cart additions or subscription modifications), the backend returns `responseType: "confirmation_required"` with a unique `confirmation_id` nonce.
- The **Confirmation Card Widget** sends `user_confirmed=true` + `confirmation_id` via `ConfirmActionUseCase`.
- Plain-text confirmation messages are strictly prohibited.

### 4. AI Memory & Privacy Controls
- Accessible via the **Health Profile & Privacy** screen (`/health-profile`).
- Explains AI memory concepts transparently.
- Provides a **Delete AI Memory** button which invokes `DELETE /api/v1/agent/memory`.
- Requires explicit user confirmation dialog before executing memory deletion.

## Running Tests

Run all chat module tests with:

```bash
flutter test test/features/chat/
```
