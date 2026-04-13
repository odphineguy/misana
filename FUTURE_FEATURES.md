# MiSana — Future Features

## App Intents / Siri Integration
- Expose key actions to Siri, Shortcuts, Spotlight, and Action Button
- Examples: "Oye Siri, prepara mi cita en MiSana", Lock Screen quick scan, Action Button → scan medication
- Requires `import AppIntents` and defining `AppIntent` structs

## Document Scanner (Understand Document)
- Scan medical documents (lab results, discharge papers, doctor's notes) and get plain-language explanation
- OCR via Vision framework is reliable, but on-device models hallucinate when interpreting medical data
- **Blocked**: Apple Foundation Models fabricates fake values instead of reading actual document content
- Revisit when on-device models improve at grounded data interpretation

## Cloud Model Option
- Option to use a cloud-based LLM (e.g. Claude API) for higher-quality responses
- Trade-off: better accuracy vs. privacy and offline capability
- Could offer as opt-in premium tier while keeping on-device as default

## Home Remedies Database
- Curated, source-backed database of common Hispanic home remedies (sábila, manzanilla, caldo de pollo, etc.)
- Each entry: what it helps with, when it's safe, when to see a doctor instead
- Validated against MedlinePlus/NIH sources

## Medication Reminders & Refill Alerts
- Source: Chronic Condition Management (Medisafe pattern)
- Scheduled push notifications for medication times
- Refill reminders based on supply/frequency
- High value: medication adherence is the #1 challenge for chronic conditions in Hispanic communities
- Already have medication list with frequency data — just need notification scheduling

## Symptom & Wellness Journal
- Source: Chronic Condition Management (Flaredown pattern) + Mental Health (Moodfit pattern)
- Daily check-in: "¿Cómo te sientes hoy?" with simple emoji/scale input
- Track symptoms over time, identify patterns and triggers
- Generate timeline to share with doctor at appointments (feeds into My Visit)
- Fits the "health bridge" — gives the doctor data, not just words

## Health Data Visualization & Trends
- Source: Fitness & Activity Tracking + General Wellness
- Weekly/monthly trend charts for HealthKit data (steps, heart rate, sleep, blood pressure)
- Currently show today's snapshot only — adding 7/30-day trends adds real value
- Simple line/bar charts, no complex dashboards
- Already have the 7-day detail views — could surface trends on Home tab

## Medication Interaction Sharing
- Source: Chronic Condition Management (Health2Sync pattern)
- Export medication list + interactions as PDF/image to share with doctor or family
- "Lleva esta lista a tu cita" — print or show on phone
- Builds on existing RxNorm interaction data

## Gentle Reminders & Wellness Nudges
- Source: General Wellness (Fabulous pattern)
- Non-intrusive daily nudge: "Toma agua", "¿Ya caminaste hoy?", "¿Dormiste bien?"
- Culturally appropriate — like a tía checking in
- Could use on-device model to personalize based on HealthKit data
- Light touch, not gamified — respects the audience

## Community / Family Sharing (Long-term)
- Source: Cross-category (Strava, Health2Sync, Sanvello patterns)
- Share health summaries with family members (e.g., adult child monitors parent's medications)
- Privacy-first: explicit opt-in, on-device data, no accounts required
- Complex feature — long-term consideration
- High value for multigenerational Hispanic households where family manages health together
