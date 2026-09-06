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

### Gaps to address / decide
- [ ] **Student identity proof** — decide one (or more) of:
  - [ ] School email domain only (e.g. `@students.nu-baliwag.edu.ph`)
  - [ ] Officer/admin approval queue before full access
  - [ ] Chapter membership request + officer approve
  - [ ] Student ID / enrollment upload for officer review
- [ ] Document who can promote members → officers
- [ ] Document what unverified users can / cannot do
- [ ] Demo script: register → verify → show member role vs officer role

### Defense answer (ready)
- [ ] Explain: login ≠ membership verification; membership is role/chapter-based and must be controlled by officers/admins
- [ ] State chosen verification method and why it fits GDGoC chapters

---

## 2. Centralized data & proof of participation

**Concern:** Applying/registering opens an external link, so there is no proof inside GoCollab of actual attendance or opportunity application. Follow-up from professor: *how would the system verify the user actually went and applied, and how does the user get back to that application later?*

### Events — what is centralized today
- [x] Event registration is stored in `event_registrations` (in-app proof of sign-up)
- [x] Unique QR ticket is generated per registration
- [x] Officer QR check-in writes `attendance` (in-app proof of actual presence)
- [x] Officers can scan and see check-in success/failure
- [ ] Demo: member registers → show QR → officer scans → attendance recorded

### Opportunities — implemented: self-report + officer follow-up
**Honest answer for the defense:** GoCollab cannot verify an action taken on a third-party site without an API integration with that specific partner, which isn't realistic for arbitrary postings. No platform can do this without owning the destination site. The fix applies the same honesty model events already use — registration is a self-report, attendance is the verified step — except here there is no in-app equivalent of "scanning," so verification is manual, not automatic:
- [x] "Mark as applied" button (`opportunity_detail_screen.dart`) writes a record to a new `opportunity_applications` table (self-reported, with an optional confirmation note e.g. a reference number or confirmation email subject)
- [x] Awards community points once per opportunity (`opportunity_apply`, +5), same idempotency guard as other point actions
- [x] Officer-visible applicants list on the opportunity detail screen (name, avatar, note, date) so officers can manually cross-check with the partner organization
- [x] Member-visible "Applied" tab in Career Hub (`opportunities_list_screen.dart`) — answers "how does the user get back to it": every opportunity they marked applied is listed there with a link back to the external `application_url`
- [x] Bookmarking (`saved_opportunities`) remains separate from applying — a bookmark is not counted as an application
- [ ] Requires running the new migration: `supabase/migrations/20260904000000_opportunity_applications.sql`
- [ ] Document clearly: **external link ≠ verified application; it's an honest self-report, mirrored by an officer-visible list for manual follow-up**

### Demo / defense checklist
- [ ] Show event registration row in app/DB as proof of interest
- [ ] Show attendance row as proof of actual event attendance
- [ ] Demo: member applies externally → returns → taps "Mark as applied" → appears in Career Hub → Applied
- [ ] Demo: officer opens the same opportunity → sees the applicant + note in the officer-only list
- [ ] State plainly: no external verification is technically possible without a partner API; self-report + officer visibility is the honest, defensible middle ground
- [ ] Explain that centralization = GoCollab DB (registrations, attendance, bookmarks, applications), not the partner website

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
| 1 | Member/student verification | Login + role only; no school proof | Choose & implement verification rule |
| 2 | Centralized proof | Events: registration + QR attendance ✅ · Opportunities: external apply ⚠️ | Add in-app application tracking |
| 3 | Location usability | Manual lat/long ⚠️ | Place search / map pin; hide coordinates |

---

*GoCollab · Professor major validation checklist · August 2026*
