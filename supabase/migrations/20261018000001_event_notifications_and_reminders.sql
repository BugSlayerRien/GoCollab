-- =====================================================================
-- Event notifications: cancelled / rescheduled notices + "starts in 1 hour"
-- =====================================================================
-- Verification and claim results are notified inside their review RPCs
-- (see 20261018000000). This adds the event side. Everything lands in the
-- in-app inbox (public.notifications); real push needs Firebase configured.

-- ---------------------------------------------------------------------
-- 1. Notify registered members when an event is cancelled or changes
-- ---------------------------------------------------------------------
create or replace function public.notify_event_changes()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
    select r.user_id, 'Event cancelled',
           format('%s has been cancelled.', new.title),
           'event_reminder', 'event', new.id
    from public.event_registrations r
    where r.event_id = new.id and r.status in ('registered', 'waitlisted');
  elsif new.status <> 'cancelled' and (
        new.start_at       is distinct from old.start_at
     or new.end_at         is distinct from old.end_at
     or new.venue_name     is distinct from old.venue_name
     or new.venue_address  is distinct from old.venue_address
     or new.is_online      is distinct from old.is_online
     or new.online_url     is distinct from old.online_url) then
    insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
    select r.user_id, 'Event updated',
           format('The schedule or venue for %s changed. Open the event for details.', new.title),
           'event_reminder', 'event', new.id
    from public.event_registrations r
    where r.event_id = new.id and r.status = 'registered';
  end if;
  return new;
end;
$$;

drop trigger if exists events_notify_changes on public.events;
create trigger events_notify_changes after update on public.events
  for each row execute function public.notify_event_changes();

-- ---------------------------------------------------------------------
-- 2. "Starts in about an hour" reminders (once per member per event)
-- ---------------------------------------------------------------------
create unique index if not exists notifications_event_starting_once
  on public.notifications (user_id, reference_id)
  where reference_type = 'event_starting';

create or replace function public.send_event_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare
  sent integer;
begin
  with due as (
    insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
    select r.user_id, 'Starting soon',
           format('%s starts at %s. Have your QR ticket ready.', e.title,
                  to_char(e.start_at at time zone 'Asia/Manila', 'HH12:MI AM')),
           'event_reminder', 'event_starting', e.id
    from public.events e
    join public.event_registrations r on r.event_id = e.id and r.status = 'registered'
    where e.status in ('upcoming', 'ongoing')
      and e.start_at > now()
      and e.start_at <= now() + interval '65 minutes'
    on conflict do nothing
    returning 1
  )
  select count(*) into sent from due;
  return sent;
end;
$$;

revoke execute on function public.send_event_reminders() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Schedule it every 10 minutes (needs the pg_cron extension)
-- ---------------------------------------------------------------------
-- If pg_cron is not enabled for your project this block only prints a
-- notice. Enable it under Database > Extensions, then re-run this file, or
-- schedule the call yourself:
--   select cron.schedule('gocollab-event-reminders', '*/10 * * * *',
--                        'select public.send_event_reminders()');
do $$
begin
  create extension if not exists pg_cron;
  perform cron.schedule('gocollab-event-reminders', '*/10 * * * *', 'select public.send_event_reminders()');
exception when others then
  raise notice 'pg_cron is not available (%). Event reminders will not be sent until it is scheduled.', sqlerrm;
end $$;
