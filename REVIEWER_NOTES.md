# MiSana — App Review Notes

Copy the section below into the **App Review Information → Notes** field in App Store Connect.

---

## App Review Notes (paste this)

Hello App Review Team — thank you for reviewing MiSana.

**Account:** No login is required. There are no test credentials. The app works immediately after the disclaimer screen.

---

### What the app does

MiSana is a free, privacy-first, bilingual (Spanish/English) educational health companion designed for Hispanic families. It does NOT diagnose, treat, or replace a doctor. The app helps users:

- Understand their medications (using NIH RxNorm and MedlinePlus data)
- Organize symptoms and questions for their next doctor visit
- Look up health topics from verified NIH/CDC sources
- Track medications and symptoms locally
- Receive medication reminders via local push notifications

---

### How to test the AI features

The app uses two on-device AI engines selected automatically by `ModelCoordinator`:

**Path A — iOS 26+ test devices (recommended for review):**
The app uses Apple Foundation Models. No download is required. AI features work immediately. This is the path most users will experience going forward.

**Path B — iOS 18-25 test devices:**
The app downloads a 2.5 GB Qwen 3 4B model from Hugging Face the first time the user opens the AI chat. Please use Wi-Fi and allow 5–10 minutes for the download. The app shows a progress bar and a clear error/retry banner if the network fails. After download, all AI features work fully offline.

If review time is constrained, please test on an iOS 26 device so the AI features are immediately available without any download.

---

### Privacy model

- **HealthKit:** Read-only. Data never leaves the device. We do not collect, transmit, or store user health data.
- **Local AI:** All inference runs on-device (Apple Foundation Models or Qwen). No prompts or responses leave the device.
- **External calls:** When the user looks up a medication or health topic, only the drug name or search term is sent to public NIH/government APIs (RxNorm, MedlinePlus, OpenFDA, NLM wsearch). No user identifiers, no health data, no personal information is ever transmitted.
- **Model download:** A one-time HTTPS download from Hugging Face for the Qwen GGUF file (~2.5 GB). This download is only needed on iOS 18-25 devices.
- **No accounts, no analytics, no ads, no tracking SDKs, no IAP.**
- The Privacy Policy in-app accurately reflects all of this.

---

### Health & safety guardrails (Guideline 1.4.1)

We have invested significant effort to make the AI safe and non-diagnostic. The system prompt (defined in `ModelCoordinator.swift`) enforces the following hard rules:

1. **Maximum 3 sentences per response** to prevent rambling clinical advice
2. **Never diagnose** — the model is positioned as an educational companion, not a doctor
3. **Never recommend specific medications by name** unless the medication appears in a verified source provided in the prompt context
4. **Never mention serious diseases** (cancer, tumors, etc.) unless the user mentions them first
5. **Never recommend exercise** when someone reports pain — see a doctor first
6. **Never comment on weight, body, or appearance** — even with HealthKit data
7. **Emergency detection:** If a user mentions chest pain, difficulty breathing, heavy bleeding, stroke symptoms, suicide/self-harm, overdose, unconsciousness, or high fever in babies, the AI's first sentence must be "Go to the ER or call 911 now." A separate UI-level emergency banner with a tappable 911 link is also shown (`HealthChatView.swift`).
8. **Source-grounded answers:** When a user asks about a condition or medication, we first retrieve verified citations from MedlinePlus/CDC/NIH and pass them to the AI as context. The model is instructed to base its response on these sources only.
9. **Persistent educational disclaimer** is pinned at the top of every chat: *"MiSana's health info is educational only, based on sources like MedlinePlus (NIH) and CDC guidelines. It does not replace your doctor."*
10. **First-launch disclaimer** clearly states the app is not a doctor, does not diagnose, and emergencies should call 911.

---

### Permission usage

| Permission | Why we need it |
|------------|----------------|
| HealthKit (read) | Display the user's health metrics on the home dashboard and provide context for AI responses. We never write to HealthKit. |
| Camera | Two purposes: (1) scan medication barcodes (EAN-13/UPC-E) on prescription bottles, (2) read text on medication labels via Vision OCR for medication entry. |
| Notifications | Local-only medication reminders. No remote push, no server. |

If camera or HealthKit permission is denied, the app continues to function with helpful fallback UI ("Open Settings" deep link, Connect Apple Health CTA on home).

---

### Privacy manifest

`PrivacyInfo.xcprivacy` declares:

- `NSPrivacyTracking: false`, `NSPrivacyTrackingDomains: []`
- `NSPrivacyCollectedDataTypeHealth` — linked: false, tracking: false, purpose: app functionality only
- Required-reason APIs declared:
  - `NSPrivacyAccessedAPICategoryUserDefaults` (1C8F.1)
  - `NSPrivacyAccessedAPICategoryDiskSpace` (85F4.1) — for free-space check before model download
  - `NSPrivacyAccessedAPICategoryFileTimestamp` (C617.1) — for file existence checks

---

### Sources

All medical content is grounded in U.S. government / NIH sources. The bundled `health_topics.json` (~1,000 bilingual topics) is derived from MedlinePlus. Drug data comes from:

- **RxNorm** (`rxnav.nlm.nih.gov`) — drug name lookup, NDC→RxCUI, interaction checking
- **MedlinePlus Connect** (`connect.medlineplus.gov`) — Spanish drug information
- **OpenFDA** (`api.fda.gov`) — UPC barcode → drug label fallback
- **NLM Web Search** (`wsearch.nlm.nih.gov`) — health topic search fallback

All endpoints are HTTPS, public, government-operated.

---

### What's NOT in the app

- No diagnosis or treatment claims
- No login, no accounts, no profiles
- No analytics, ad tracking, ATT, or IDFA
- No in-app purchases or subscriptions
- No social features or user-to-user content
- No deep links, universal links, widgets, app extensions, or background modes
- No HealthKit writes (read-only)
- No vision/multimodal AI input — chat is text-only

---

### Bilingual support

The user can switch between English and Spanish in the disclaimer screen and Settings. All UI, system prompts, permission strings, notifications, and exports are fully bilingual. The Spanish prompt uses culturally appropriate Mexican Spanish (e.g., "mijo/mija") and respects cultural health practices (sobador, empacho, mal de ojo) without judgment.

---

### Contact

For questions during review: **support@misana.app**

Thank you for taking the time to review MiSana. We've worked hard to build a safe, accurate, and culturally grounded health companion for an underserved community.
