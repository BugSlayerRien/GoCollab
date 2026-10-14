-- =====================================================================
-- 1. Server-side attendance check-in
-- =====================================================================
-- The old client flow inserted the attendance row, then tried to insert an
-- `event_attend` engagement log on the MEMBER's behalf while signed in as the
-- OFFICER. engagement_logs RLS only allows `user_id = auth.uid()`, so that
-- insert failed and the +25 attendance points were never awarded. Doing the
-- whole check-in in one SECURITY DEFINER function fixes that and lets the
-- server enforce the rules instead of trusting the client.
create or replace function public.check_in_attendee(
  p_event_id uuid,
  p_qr_code  text default null,
  p_user_id  uuid default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  reg        record;
  ev         record;
  attendee   text;
begin
  if not public.is_officer() then
    raise exception 'Only officers can check attendees in.' using errcode = '42501';
  end if;

  select * into ev from public.events where id = p_event_id;
  if ev.id is null then
    raise exception 'Event not found.';
  end if;

  if ev.status = 'cancelled' then
    raise exception 'This event was cancelled.';
  end if;
  if now() < ev.start_at - interval '2 hours' then
    raise exception 'Check-in opens 2 hours before the event starts.';
  end if;
  if now() > ev.end_at + interval '6 hours' then
    raise exception 'Check-in for this event has closed.';
  end if;

  if p_qr_code is not null then
    select * into reg from public.event_registrations
    where event_id = p_event_id and qr_code = p_qr_code;
  elsif p_user_id is not null then
    select * into reg from public.event_registrations
    where event_id = p_event_id and user_id = p_user_id;
  else
    raise exception 'A QR code or member is required.';
  end if;

  if reg.id is null then
    raise exception 'This member is not registered for this event.';
  end if;
  if reg.status = 'cancelled' then
    raise exception 'This registration was cancelled.';
  end if;

  select full_name into attendee from public.profiles where id = reg.user_id;

  if exists (select 1 from public.attendance where event_id = p_event_id and user_id = reg.user_id) then
    raise exception '% has already checked in.', coalesce(attendee, 'This member');
  end if;

  insert into public.attendance (event_id, user_id, registration_id, checked_in_by, method)
  values (p_event_id, reg.user_id, reg.id, auth.uid(),
          case when p_qr_code is not null then 'qr' else 'manual' end);

  update public.event_registrations set status = 'attended' where id = reg.id;

  -- Awards +25 via the engagement_logs trigger; unique index prevents repeats.
  insert into public.engagement_logs (user_id, action_type, reference_type, reference_id)
  values (reg.user_id, 'event_attend', 'event', p_event_id)
  on conflict do nothing;

  return coalesce(attendee, 'Attendee');
end;
$$;

-- =====================================================================
-- 2. Members can see the partner behind an event
-- =====================================================================
-- `partners` is officer-only (it holds contact people, emails and phone
-- numbers), so a plain join returned NULL for every member and the partner
-- chip never showed. This view exposes only the promotional columns, to any
-- signed-in user.
create or replace view public.partner_public as
select id, name, logo_url, description, website, category
from public.partners
where collaboration_status <> 'ended';

grant select on public.partner_public to authenticated;
