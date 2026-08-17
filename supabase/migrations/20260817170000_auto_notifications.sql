-- Auto-create in-app notifications for registrations, announcements,
-- opportunities, and event check-ins.

create or replace function public.create_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_reference_type text default null,
  p_reference_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
  values (p_user_id, p_title, p_body, p_type, p_reference_type, p_reference_id);
end;
$$;

-- Registration confirmed when a member registers (or re-registers after cancel).
create or replace function public.notify_event_registration()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  event_title text;
begin
  if new.status <> 'registered' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = 'registered' then
    return new;
  end if;

  select title into event_title from public.events where id = new.event_id;

  perform public.create_notification(
    new.user_id,
    'Registration confirmed',
    format('You are registered for %s.', coalesce(event_title, 'an event')),
    'registration_confirmation',
    'event',
    new.event_id
  );

  return new;
end;
$$;

drop trigger if exists event_registrations_notify on public.event_registrations;
create trigger event_registrations_notify
after insert or update on public.event_registrations
for each row execute function public.notify_event_registration();

-- New announcement → notify every member/officer except the author.
create or replace function public.notify_new_announcement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
  select
    p.id,
    'New announcement',
    left(new.title || case when char_length(new.body) > 0 then ': ' || new.body else '' end, 240),
    'announcement',
    'announcement',
    new.id
  from public.profiles p
  where p.id <> coalesce(new.created_by, '00000000-0000-0000-0000-000000000000'::uuid);

  return new;
end;
$$;

drop trigger if exists announcements_notify on public.announcements;
create trigger announcements_notify
after insert on public.announcements
for each row execute function public.notify_new_announcement();

-- New career opportunity → notify all members except the poster.
create or replace function public.notify_new_opportunity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
  select
    p.id,
    'New career opportunity',
    left(new.title || ' · ' || new.organization, 240),
    'career_opportunity',
    'opportunity',
    new.id
  from public.profiles p
  where p.id <> coalesce(new.posted_by, '00000000-0000-0000-0000-000000000000'::uuid);

  return new;
end;
$$;

drop trigger if exists opportunities_notify on public.opportunities;
create trigger opportunities_notify
after insert on public.opportunities
for each row execute function public.notify_new_opportunity();

-- QR check-in → notify the attendee.
create or replace function public.notify_event_check_in()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  event_title text;
begin
  select title into event_title from public.events where id = new.event_id;

  perform public.create_notification(
    new.user_id,
    'Checked in successfully',
    format('You checked in to %s.', coalesce(event_title, 'your event')),
    'event_reminder',
    'event',
    new.event_id
  );

  return new;
end;
$$;

drop trigger if exists attendance_notify on public.attendance;
create trigger attendance_notify
after insert on public.attendance
for each row execute function public.notify_event_check_in();

-- Realtime updates for the notifications inbox badge.
do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;
