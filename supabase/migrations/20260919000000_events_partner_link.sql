-- 1. Defense-in-depth: registration deadline must be before the event starts.
--    The app already blocks this in the create/edit form; this constraint
--    stops it being violated by any other write path (API, seed data, etc).
alter table public.events drop constraint if exists events_registration_deadline_check;
alter table public.events add constraint events_registration_deadline_check
  check (registration_deadline is null or registration_deadline < start_at);

-- 2. Let an event optionally display a partner/sponsor, so officers can
--    attach a partner from Partnerships directly while creating an event.
alter table public.events add column if not exists partner_id uuid
  references public.partners (id) on delete set null;

create index if not exists events_partner_idx on public.events (partner_id);
