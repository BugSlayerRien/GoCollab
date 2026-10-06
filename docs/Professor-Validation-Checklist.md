# GoCollab — Major Validation Checklist

Professor review items. Use this as a pass/fail checklist for demo and documentation.

---

## 1. Account authentication & member/student verification

**Concern:** Not just Google login — how is the account verified as a real member/student?

### Current system (baseline)
- [ ] Email/password registration works
- [ ] Google Sign-In works
- [ ] Email verification (Supabase confirmation) works for email/password
- [ ] New accounts default to `role_id = 1` (member)
- [ ] Officer access requires role promotion (`role_id = 2`)

### Implemented: automatic school-email verification + officer fallback
The design goal was verification with **minimal manual input from the user**, so it runs in two layers:
- [x] **School email domain = instant automatic verification.** A `BEFORE INSERT` trigger on `profiles` checks the signup email's domain against the `school_email_domains` table and marks the account verified on the spot. Zero extra steps for the user, and it runs server-side so it cannot be forged from the client.
- [x] **Student ID + officer review for everyone else.** Members signing up with a personal Gmail submit a student number and a photo of their school ID, which lands in an officer-only review queue (approve / reject with a reason).
- [x] **Unverified members can browse but not participate** — blocked from registering for events and therefore from earning points.
- [x] **Enforced in RLS, not just the UI** — the `event_registrations` insert policy requires `public.is_verified()`. A disabled button is cosmetic; the policy is the actual gate.
- [x] **Privilege-escalation hole closed** — `profiles_update_own` granted UPDATE on the whole row, so a member could previously PATCH their own `role_id` straight against the REST API. A `BEFORE UPDATE` guard trigger now rejects non-officer changes to `role_id`, `verification_status`, `verified_at`, `verified_by`, and `student_number`.
- [x] **ID photos stored privately** — unlike avatars/banners, the `verification-docs` bucket is non-public; officers view submissions through short-lived signed URLs.
- [ ] Requires running `supabase/migrations/20260924000000_member_verification.sql` and `20260924000001_verification_docs_storage.sql`
- [ ] Confirm the seeded domains in that migration match your real campus domains

### Defense answer (ready)
- [x] Login ≠ membership verification: a Google account proves only that the email exists. Verification here means the account is tied to a school-issued identity.
- [x] Why school email first: it's the only signal that needs *no* user effort at all and can't be self-asserted — the school controls who holds one.
- [x] Why an officer queue as fallback: it covers members whose Google account is personal, without forcing everyone through manual review.
- [ ] Demo script: sign up with school email → already verified · sign up with Gmail → submit ID → officer approves → verified
- [ ] Known limit to state honestly: this proves *school enrolment*, not *GDGoC club membership* — officer approval is what confirms the latter. OCR of the ID is a planned upgrade to reduce officer effort further.

---

## 2. Centralized data & proof of participation

**Concern:** Applying/registering opens an external link, so there is no proof inside GoCollab of actual attendance or opportunity application. Follow-up from professor: *how would the system verify the user actually went and applied, and how does the user get back to that application later?*

### Events — what is centralized today
- [x] Event registration is stored in `event_registrations` (in-app proof of sign-up)
- [x] Unique QR ticket is generated per registration
- [x] Officer QR check-in writes `attendance` (in-app proof of actual presence)
- [x] Officers can scan and see check-in success/failure
- [ ] Demo: member registers → show QR → officer scans → attendance recorded

### Opportunities — external apply (self-report feature removed)
**Status:** a self-report "Mark as applied" feature (with an officer-visible applicant list) was built and then deliberately removed on request — the honesty-model answer wasn't the direction wanted. The gap is open again pending a different approach.
- [ ] Opportunity "Apply" currently uses external `application_url` (leaves the app)
- [ ] Bookmarking (`saved_opportunities`) is tracked, but **not** a formal application status
- [ ] See the brainstorm section at the bottom of this doc for the next direction under consideration

### Demo / defense checklist
- [ ] Show event registration row in app/DB as proof of interest
- [ ] Show attendance row as proof of actual event attendance
- [ ] Honestly state opportunity apply is external today, with the proposed fix still under discussion
- [ ] Explain that centralization = GoCollab DB (registrations, attendance, bookmarks), not the partner website

---

## 3. Event location input & display (lat/long usability)

**Concern:** Officers may not know how to enter latitude/longitude. Need an easier, more efficient way to set and show location.

### Current system (baseline)
- [x] Event form has venue name + address fields
- [x] Latitude / longitude inputs remain, but now inside a collapsed "Fine-tune coordinates" section — manual entry is a fallback, not the primary path
- [x] Map preview uses lat/long via OpenStreetMap
- [x] "Open in Maps" uses lat/long query

### Implemented: address search / place picker
- [x] **Address search** (`create_event_sheet.dart`) — officer types a venue or address, results come from OpenStreetMap's Nominatim API (`lib/core/services/place_search_service.dart`), no API key needed since the app already runs on `flutter_map` + OSM tiles (no Google Maps SDK)
- [x] Debounced (~500ms) so it doesn't hammer the free Nominatim endpoint
- [x] Picking a result auto-fills venue address, latitude, and longitude in one tap
- [x] Manual lat/long fields kept as a fallback for venues Nominatim doesn't find, tucked into an expandable section so they don't dominate the form

### Display (unchanged, already good)
- [x] Shows readable address first, map only when coordinates exist
- [x] Online events already hide location inputs and show a meeting URL instead

### Demo / defense checklist
- [ ] Demo: create event → type a venue name in "Search for a place" → pick a result → address + coordinates fill automatically
- [ ] Show the collapsed "Fine-tune coordinates" section as the manual fallback, not the primary flow
- [ ] Explain the OSM/Nominatim choice keeps the app free of a Google Maps API key, consistent with the existing map stack

---

## Quick status summary

| # | Topic | Status today | Action needed |
|---|---|---|---|
| 1 | Member/student verification | School-email auto-verify + officer ID review ✅ | Run the two migrations; confirm campus domains |
| 2 | Centralized proof | Events: registration + QR attendance ✅ · Opportunities: external apply ⚠️ | Add in-app application tracking |
| 3 | Location usability | Manual lat/long ⚠️ | Place search / map pin; hide coordinates |

---

*GoCollab · Professor major validation checklist · August 2026*
