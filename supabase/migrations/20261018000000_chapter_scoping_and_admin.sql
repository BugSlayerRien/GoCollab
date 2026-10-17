-- =====================================================================
-- Chapter-scoped officers + Admin tier + audit log
-- =====================================================================
-- Before this migration every officer policy was `is_officer()` (role = 2),
-- so an officer from one chapter could verify, approve, edit or read the
-- data of every other chapter. Now:
--
--   member  < officer (acts ONLY inside their own chapter) < admin
--
--   admin   = platform maintainer. Creates chapters, appoints/demotes
--             officers, assigns members to chapters, manages school-email
--             domains and the GDG feed, reads the audit log. An admin does
--             NOT review IDs/claims or run events and cannot read ID photos.
--
-- The first admin is set by hand (see the end of this file).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Roles
-- ---------------------------------------------------------------------
insert into public.roles (id, name, description) values
  (3, 'admin', 'Platform administrator (chapters, officers, audit log)')
on conflict (id) do nothing;

update public.roles set description = 'GDGoC chapter officer' where id = 2;

-- ---------------------------------------------------------------------
-- 2. Helpers
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role_id = 3);
$$;

create or replace function public.my_chapter_id()
returns uuid language sql stable security definer set search_path = public as $$
  select p.chapter_id from public.profiles p where p.id = auth.uid();
$$;

create or replace function public.chapter_of(p_user uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select p.chapter_id from public.profiles p where p.id = p_user;
$$;

create or replace function public.event_chapter(p_event uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select e.chapter_id from public.events e where e.id = p_event;
$$;

-- True only for an officer whose own chapter is `p_chapter`.
create or replace function public.is_officer_of(p_chapter uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select p_chapter is not null and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role_id = 2 and p.chapter_id = p_chapter
  );
$$;

create or replace function public.safe_uuid(p_text text)
returns uuid language plpgsql immutable as $$
begin
  return p_text::uuid;
exception when others then
  return null;
end;
$$;

-- Storage object -> chapter of the member whose folder it is in.
create or replace function public.storage_owner_chapter(p_name text)
returns uuid language sql stable security definer set search_path = public as $$
  select public.chapter_of(public.safe_uuid((storage.foldername(p_name))[1]));
$$;

-- Server-side code that legitimately writes protected profile columns flips
-- this transaction-local flag so the guard trigger lets it through.
create or replace function public.is_system_write()
returns boolean language sql stable as $$
  select coalesce(current_setting('gocollab.system_write', true), '') = 'on';
$$;

-- ---------------------------------------------------------------------
-- 3. Audit log (append-only; written only by the functions below)
-- ---------------------------------------------------------------------
create table if not exists public.audit_log (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid references public.profiles (id) on delete set null,
  chapter_id  uuid,
  action      text not null,
  target_type text,
  target_id   text,
  detail      jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists audit_log_chapter_idx on public.audit_log (chapter_id, created_at desc);
create index if not exists audit_log_created_idx on public.audit_log (created_at desc);

alter table public.audit_log enable row level security;

drop policy if exists "audit_log_select_scoped" on public.audit_log;
create policy "audit_log_select_scoped" on public.audit_log
  for select to authenticated
  using (public.is_admin() or public.is_officer_of(chapter_id));
-- No insert/update/delete policy: nothing outside SECURITY DEFINER code can write.

create or replace function public.write_audit(
  p_chapter     uuid,
  p_action      text,
  p_target_type text default null,
  p_target_id   text default null,
  p_detail      jsonb default '{}'::jsonb
)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_log (actor_id, chapter_id, action, target_type, target_id, detail)
  values (auth.uid(), p_chapter, p_action, p_target_type, p_target_id, coalesce(p_detail, '{}'::jsonb));
end;
$$;

revoke execute on function public.write_audit(uuid, text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.create_notification(uuid, text, text, text, text, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. Default chapter + backfill (so existing officers keep working)
-- ---------------------------------------------------------------------
insert into public.chapters (name, campus, region)
values ('GDGoC NU Baliwag', 'National University - Baliwag', 'Region III')
on conflict do nothing;

do $$
declare
  dc uuid;
begin
  select id into dc from public.chapters
  where name = 'GDGoC NU Baliwag' and campus = 'National University - Baliwag';

  update public.school_email_domains set chapter_id = dc where chapter_id is null;

  -- Members/officers without a chapter: by email domain, else the default.
  update public.profiles p
  set chapter_id = coalesce(
        (select d.chapter_id from public.school_email_domains d
         where d.domain = lower(split_part(p.email, '@', 2))),
        dc)
  where p.chapter_id is null;

  alter table public.opportunities  add column if not exists chapter_id uuid references public.chapters (id) on delete restrict;
  alter table public.partners       add column if not exists chapter_id uuid references public.chapters (id) on delete restrict;
  alter table public.sponsorships   add column if not exists chapter_id uuid references public.chapters (id) on delete restrict;
  alter table public.meetings       add column if not exists chapter_id uuid references public.chapters (id) on delete restrict;
  alter table public.communications add column if not exists chapter_id uuid references public.chapters (id) on delete restrict;
  alter table public.gdg_chapters   add column if not exists owner_chapter_id uuid references public.chapters (id) on delete cascade;

  update public.events        set chapter_id = coalesce(public.chapter_of(created_by), dc) where chapter_id is null;
  update public.announcements set chapter_id = coalesce(public.chapter_of(created_by), dc) where chapter_id is null;
  update public.opportunities set chapter_id = coalesce(public.chapter_of(posted_by), dc) where chapter_id is null;
  update public.partners      set chapter_id = coalesce(public.chapter_of(created_by), dc) where chapter_id is null;
  update public.sponsorships  s set chapter_id = coalesce((select p.chapter_id from public.partners p where p.id = s.partner_id), dc) where s.chapter_id is null;
  update public.meetings      m set chapter_id = coalesce((select p.chapter_id from public.partners p where p.id = m.partner_id), dc) where m.chapter_id is null;
  update public.communications c set chapter_id = coalesce((select p.chapter_id from public.partners p where p.id = c.partner_id), dc) where c.chapter_id is null;
  update public.gdg_chapters  set owner_chapter_id = dc where owner_chapter_id is null;
end $$;

-- New rows inherit the acting officer's chapter; RLS then verifies it.
alter table public.events          alter column chapter_id set default public.my_chapter_id();
alter table public.announcements   alter column chapter_id set default public.my_chapter_id();
alter table public.opportunities   alter column chapter_id set default public.my_chapter_id();
alter table public.partners        alter column chapter_id set default public.my_chapter_id();
alter table public.sponsorships    alter column chapter_id set default public.my_chapter_id();
alter table public.meetings        alter column chapter_id set default public.my_chapter_id();
alter table public.communications  alter column chapter_id set default public.my_chapter_id();
alter table public.gdg_chapters    alter column owner_chapter_id set default public.my_chapter_id();
alter table public.school_email_domains alter column chapter_id set default public.my_chapter_id();

create index if not exists opportunities_chapter_idx on public.opportunities (chapter_id);
create index if not exists partners_chapter_idx on public.partners (chapter_id);
create index if not exists announcements_chapter_idx on public.announcements (chapter_id);

-- A chapter that still has members cannot be deleted.
create or replace function public.block_chapter_delete_with_members()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.profiles where chapter_id = old.id) then
    raise exception 'This chapter still has members. Move them to another chapter first.' using errcode = '23503';
  end if;
  return old;
end;
$$;

drop trigger if exists chapters_block_delete on public.chapters;
create trigger chapters_block_delete before delete on public.chapters
  for each row execute function public.block_chapter_delete_with_members();

-- ---------------------------------------------------------------------
-- 5. Profiles: lock chapter / role / points, assign chapter on signup
-- ---------------------------------------------------------------------
create or replace function public.guard_protected_profile_columns()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or public.is_system_write() or public.is_admin() then
    return new;
  end if;

  if new.role_id             is distinct from old.role_id
     or new.verification_status is distinct from old.verification_status
     or new.verified_at      is distinct from old.verified_at
     or new.verified_by      is distinct from old.verified_by
     or new.student_number   is distinct from old.student_number
     or new.chapter_id       is distinct from old.chapter_id
     or new.points           is distinct from old.points then
    raise exception 'Protected profile columns can only be changed by the system or an administrator.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

-- Runs before profiles_auto_verify (triggers fire alphabetically).
create or replace function public.profiles_sanitize_insert()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  email_domain text;
  matched uuid;
begin
  if auth.uid() is not null and not public.is_system_write() then
    new.role_id := 1;
    new.points := 0;
    new.chapter_id := null;
    new.verification_status := 'unverified';
    new.verified_at := null;
    new.verified_by := null;
    new.student_number := null;
  end if;

  if new.chapter_id is null then
    email_domain := lower(split_part(coalesce(new.email, ''), '@', 2));
    select d.chapter_id into matched
    from public.school_email_domains d
    where d.domain = email_domain and d.chapter_id is not null;
    new.chapter_id := matched;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_0_sanitize_insert on public.profiles;
create trigger profiles_0_sanitize_insert before insert on public.profiles
  for each row execute function public.profiles_sanitize_insert();

-- Officers can no longer edit arbitrary profiles directly.
drop policy if exists "profiles_officer_update_any" on public.profiles;

-- Points are awarded by a trigger that runs as the member, so it flags itself.
create or replace function public.award_engagement_points()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  delta integer;
  already_awarded boolean;
begin
  if new.reference_id is not null
     and new.action_type in ('opportunity_save','opportunity_apply','event_register','event_attend','certificate_earned') then
    select exists (
      select 1 from public.engagement_logs el
      where el.user_id = new.user_id
        and el.action_type = new.action_type
        and el.reference_id = new.reference_id
        and el.id <> new.id
    ) into already_awarded;

    if already_awarded then
      return new;
    end if;
  end if;

  delta := case new.action_type
    when 'event_register' then 5
    when 'event_attend' then 25
    when 'opportunity_save' then 1
    when 'opportunity_apply' then 10
    when 'certificate_earned' then 50
    when 'profile_update' then 2
    else 1
  end;

  perform set_config('gocollab.system_write', 'on', true);
  update public.profiles set points = points + delta where id = new.user_id;

  return new;
end;
$$;

-- A member whose email did not match a school domain picks a chapter once
-- (before submitting their ID). After that only an admin can move them.
create or replace function public.choose_my_chapter(p_chapter uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in first.' using errcode = '42501';
  end if;
  if not exists (select 1 from public.chapters where id = p_chapter and is_active) then
    raise exception 'That chapter does not exist.';
  end if;
  if public.my_chapter_id() is not null then
    raise exception 'Your chapter is already set. Ask an administrator to change it.' using errcode = '42501';
  end if;

  perform set_config('gocollab.system_write', 'on', true);
  update public.profiles set chapter_id = p_chapter where id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------
-- 6. Admin RPCs
-- ---------------------------------------------------------------------
create or replace function public.set_member_role(p_user uuid, p_role smallint)
returns void language plpgsql security definer set search_path = public as $$
declare
  t record;
begin
  if not public.is_admin() then
    raise exception 'Only administrators can change roles.' using errcode = '42501';
  end if;
  if p_role not in (1, 2) then
    raise exception 'A role must be member or officer.';
  end if;

  select id, role_id, chapter_id into t from public.profiles where id = p_user for update;
  if t.id is null then
    raise exception 'Member not found.';
  end if;
  if t.role_id = 3 then
    raise exception 'Administrators are managed directly in the database.' using errcode = '42501';
  end if;
  if p_role = 2 and t.chapter_id is null then
    raise exception 'Assign the member to a chapter before making them an officer.';
  end if;

  perform set_config('gocollab.system_write', 'on', true);
  update public.profiles set role_id = p_role where id = p_user;

  perform public.write_audit(t.chapter_id,
    case when p_role = 2 then 'role.promote' else 'role.demote' end,
    'profile', p_user::text, jsonb_build_object('from', t.role_id, 'to', p_role));
  perform public.create_notification(p_user,
    case when p_role = 2 then 'You are now an officer' else 'Your officer role was removed' end,
    case when p_role = 2 then 'You can now manage your chapter in GoCollab.' else 'You are a regular member again.' end,
    'general', 'profile', p_user);
end;
$$;

create or replace function public.assign_member_chapter(p_user uuid, p_chapter uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  old_chapter uuid;
begin
  if not public.is_admin() then
    raise exception 'Only administrators can move members between chapters.' using errcode = '42501';
  end if;
  if not exists (select 1 from public.chapters where id = p_chapter and is_active) then
    raise exception 'That chapter does not exist.';
  end if;

  select chapter_id into old_chapter from public.profiles where id = p_user for update;
  if not found then
    raise exception 'Member not found.';
  end if;

  perform set_config('gocollab.system_write', 'on', true);
  update public.profiles set chapter_id = p_chapter where id = p_user;

  perform public.write_audit(p_chapter, 'member.chapter_assigned', 'profile', p_user::text,
    jsonb_build_object('from', old_chapter, 'to', p_chapter));
end;
$$;

grant execute on function public.set_member_role(uuid, smallint) to authenticated;
grant execute on function public.assign_member_chapter(uuid, uuid) to authenticated;
grant execute on function public.choose_my_chapter(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 7. Chapters + school-email domains + GDG feed
-- ---------------------------------------------------------------------
drop policy if exists "chapters_officer_write" on public.chapters;
drop policy if exists "chapters_admin_write" on public.chapters;
create policy "chapters_admin_write" on public.chapters for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "school_email_domains_officer_write" on public.school_email_domains;
create policy "school_email_domains_scoped_write" on public.school_email_domains
  for all to authenticated
  using (public.is_admin() or public.is_officer_of(chapter_id))
  with check (public.is_admin() or public.is_officer_of(chapter_id));

drop policy if exists "gdg_chapters_officer_write" on public.gdg_chapters;
drop policy if exists "gdg_chapters_scoped_write" on public.gdg_chapters;
create policy "gdg_chapters_scoped_write" on public.gdg_chapters
  for all to authenticated
  using (public.is_admin() or public.is_officer_of(owner_chapter_id))
  with check (public.is_admin() or public.is_officer_of(owner_chapter_id));

create or replace function public.audit_chapter_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    perform public.write_audit(old.id, 'chapter.deleted', 'chapter', old.id::text, jsonb_build_object('name', old.name));
    return old;
  end if;
  perform public.write_audit(new.id,
    case when tg_op = 'INSERT' then 'chapter.created' else 'chapter.updated' end,
    'chapter', new.id::text, jsonb_build_object('name', new.name, 'is_active', new.is_active));
  return new;
end;
$$;

drop trigger if exists chapters_audit on public.chapters;
create trigger chapters_audit after insert or update or delete on public.chapters
  for each row execute function public.audit_chapter_change();

create or replace function public.audit_domain_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    perform public.write_audit(old.chapter_id, 'domain.removed', 'school_email_domain', old.domain, '{}'::jsonb);
    return old;
  end if;
  perform public.write_audit(new.chapter_id, 'domain.added', 'school_email_domain', new.domain, '{}'::jsonb);
  return new;
end;
$$;

drop trigger if exists school_email_domains_audit on public.school_email_domains;
create trigger school_email_domains_audit after insert or delete on public.school_email_domains
  for each row execute function public.audit_domain_change();

-- ---------------------------------------------------------------------
-- 8. Chapter-scoped policies on chapter-owned content
-- ---------------------------------------------------------------------
-- events / announcements: everyone reads; only the creating officer of the
-- chapter writes (same rule as before, plus the chapter check).
drop policy if exists "events_officer_insert" on public.events;
drop policy if exists "events_officer_update_own" on public.events;
drop policy if exists "events_officer_delete_own" on public.events;
create policy "events_officer_insert" on public.events for insert to authenticated
  with check (public.is_officer_of(chapter_id) and created_by = auth.uid());
create policy "events_officer_update_own" on public.events for update to authenticated
  using (public.is_officer_of(chapter_id) and created_by = auth.uid())
  with check (public.is_officer_of(chapter_id) and created_by = auth.uid());
create policy "events_officer_delete_own" on public.events for delete to authenticated
  using (public.is_officer_of(chapter_id) and created_by = auth.uid());

drop policy if exists "announcements_officer_insert" on public.announcements;
drop policy if exists "announcements_officer_update_own" on public.announcements;
drop policy if exists "announcements_officer_delete_own" on public.announcements;
create policy "announcements_officer_insert" on public.announcements for insert to authenticated
  with check (public.is_officer_of(chapter_id) and created_by = auth.uid());
create policy "announcements_officer_update_own" on public.announcements for update to authenticated
  using (public.is_officer_of(chapter_id) and created_by = auth.uid())
  with check (public.is_officer_of(chapter_id) and created_by = auth.uid());
create policy "announcements_officer_delete_own" on public.announcements for delete to authenticated
  using (public.is_officer_of(chapter_id) and created_by = auth.uid());

-- opportunities: everyone reads; officers of the owning chapter write.
drop policy if exists "opportunities_officer_write" on public.opportunities;
create policy "opportunities_officer_write" on public.opportunities for all to authenticated
  using (public.is_officer_of(chapter_id)) with check (public.is_officer_of(chapter_id));

-- partners & friends: private to the owning chapter's officers (contact PII).
drop policy if exists "partners_officer_all" on public.partners;
drop policy if exists "sponsorships_officer_all" on public.sponsorships;
drop policy if exists "meetings_officer_all" on public.meetings;
drop policy if exists "communications_officer_all" on public.communications;
create policy "partners_officer_all" on public.partners for all to authenticated
  using (public.is_officer_of(chapter_id)) with check (public.is_officer_of(chapter_id));
create policy "sponsorships_officer_all" on public.sponsorships for all to authenticated
  using (public.is_officer_of(chapter_id)) with check (public.is_officer_of(chapter_id));
create policy "meetings_officer_all" on public.meetings for all to authenticated
  using (public.is_officer_of(chapter_id)) with check (public.is_officer_of(chapter_id));
create policy "communications_officer_all" on public.communications for all to authenticated
  using (public.is_officer_of(chapter_id)) with check (public.is_officer_of(chapter_id));

-- ---------------------------------------------------------------------
-- 9. Registrations, attendance, certificates (scoped through the event)
-- ---------------------------------------------------------------------
drop policy if exists "event_registrations_select_own_or_officer" on public.event_registrations;
drop policy if exists "event_registrations_update_own_or_officer" on public.event_registrations;
drop policy if exists "event_registrations_delete_own_or_officer" on public.event_registrations;
create policy "event_registrations_select_own_or_officer" on public.event_registrations for select to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.event_chapter(event_id)));
create policy "event_registrations_update_own_or_officer" on public.event_registrations for update to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.event_chapter(event_id)))
  with check (user_id = auth.uid() or public.is_officer_of(public.event_chapter(event_id)));
create policy "event_registrations_delete_own_or_officer" on public.event_registrations for delete to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.event_chapter(event_id)));

-- A member may only register/cancel; they can never mark themselves attended
-- or move a registration to another event/user.
create or replace function public.guard_registration_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or public.is_system_write() then
    return new;
  end if;

  if new.event_id is distinct from old.event_id
     or new.user_id is distinct from old.user_id
     or new.qr_code is distinct from old.qr_code then
    raise exception 'A registration cannot be moved.' using errcode = '42501';
  end if;

  if public.is_officer_of(public.event_chapter(old.event_id)) then
    return new;
  end if;

  if new.status is distinct from old.status
     and not (new.status in ('registered', 'cancelled')
              and old.status in ('registered', 'cancelled', 'waitlisted')) then
    raise exception 'Only an officer can change this registration.' using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists event_registrations_guard on public.event_registrations;
create trigger event_registrations_guard before update on public.event_registrations
  for each row execute function public.guard_registration_update();

-- attendance is written only by the check-in / undo RPCs below.
drop policy if exists "attendance_select_own_or_officer" on public.attendance;
drop policy if exists "attendance_officer_write" on public.attendance;
drop policy if exists "attendance_officer_update" on public.attendance;
create policy "attendance_select_own_or_officer" on public.attendance for select to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.event_chapter(event_id)));

drop policy if exists "certificates_select_own_or_officer" on public.certificates;
drop policy if exists "certificates_officer_write" on public.certificates;
create policy "certificates_select_own_or_officer" on public.certificates for select to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.event_chapter(event_id)));
create policy "certificates_officer_write" on public.certificates for all to authenticated
  using (public.is_officer_of(public.event_chapter(event_id)))
  with check (public.is_officer_of(public.event_chapter(event_id)));

-- ---------------------------------------------------------------------
-- 10. Engagement logs + notifications
-- ---------------------------------------------------------------------
drop policy if exists "engagement_logs_select_own_or_officer" on public.engagement_logs;
drop policy if exists "engagement_logs_insert_own" on public.engagement_logs;
create policy "engagement_logs_select_own_or_officer" on public.engagement_logs for select to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.chapter_of(user_id)));

-- Clients may log only the two actions that have a real row behind them;
-- attendance, claims and certificates are logged by server functions.
create policy "engagement_logs_insert_own" on public.engagement_logs for insert to authenticated
  with check (
    user_id = auth.uid()
    and (
      (action_type = 'event_register' and exists (
        select 1 from public.event_registrations r
        where r.user_id = auth.uid() and r.event_id = reference_id and r.status = 'registered'))
      or
      (action_type = 'opportunity_save' and exists (
        select 1 from public.saved_opportunities s
        where s.user_id = auth.uid() and s.opportunity_id = reference_id))
    )
  );

drop policy if exists "notifications_officer_insert" on public.notifications;
drop policy if exists "notifications_insert_own" on public.notifications;
create policy "notifications_insert_own" on public.notifications for insert to authenticated
  with check (user_id = auth.uid());

-- Fan-out stays inside the author's chapter.
create or replace function public.notify_new_announcement()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
  select p.id, 'New announcement',
         left(new.title || case when char_length(new.body) > 0 then ': ' || new.body else '' end, 240),
         'announcement', 'announcement', new.id
  from public.profiles p
  where p.id <> coalesce(new.created_by, '00000000-0000-0000-0000-000000000000'::uuid)
    and p.chapter_id is not distinct from new.chapter_id;
  return new;
end;
$$;

create or replace function public.notify_new_opportunity()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
  select p.id, 'New career opportunity', left(new.title || ' · ' || new.organization, 240),
         'career_opportunity', 'opportunity', new.id
  from public.profiles p
  where p.id <> coalesce(new.posted_by, '00000000-0000-0000-0000-000000000000'::uuid)
    and p.chapter_id is not distinct from new.chapter_id;
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 11. Verification (scoped to the applicant's chapter)
-- ---------------------------------------------------------------------
drop policy if exists "verification_requests_select_own_or_officer" on public.verification_requests;
drop policy if exists "verification_requests_insert_own" on public.verification_requests;
drop policy if exists "verification_requests_officer_update" on public.verification_requests;
create policy "verification_requests_select_own_or_officer" on public.verification_requests
  for select to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.chapter_of(user_id)));
create policy "verification_requests_insert_own" on public.verification_requests
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and reviewed_by is null and reviewed_at is null and rejection_reason is null
    and public.my_chapter_id() is not null
  );
-- Decisions go through review_verification_request() only.

create or replace function public.review_verification_request(
  p_request_id uuid,
  p_approve    boolean,
  p_reason     text default null
)
returns void language plpgsql security definer set search_path = public as $$
declare
  target_user uuid;
  target_student_number text;
  target_chapter uuid;
begin
  select user_id, student_number
    into target_user, target_student_number
  from public.verification_requests
  where id = p_request_id and status = 'pending'
  for update;

  if target_user is null then
    raise exception 'Verification request not found or already reviewed.' using errcode = 'P0002';
  end if;

  target_chapter := public.chapter_of(target_user);
  if not public.is_officer_of(target_chapter) then
    raise exception 'Only an officer of the member''s chapter can review this request.' using errcode = '42501';
  end if;
  if target_user = auth.uid() then
    raise exception 'You cannot review your own verification request.' using errcode = '42501';
  end if;

  update public.verification_requests
  set status           = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by      = auth.uid(),
      reviewed_at      = now(),
      rejection_reason = case when p_approve then null else p_reason end
  where id = p_request_id;

  perform set_config('gocollab.system_write', 'on', true);
  update public.profiles
  set verification_status = case when p_approve then 'verified' else 'rejected' end,
      verified_at         = case when p_approve then now() else null end,
      verified_by         = case when p_approve then auth.uid() else null end,
      student_number      = case when p_approve then target_student_number else student_number end
  where id = target_user;

  perform public.write_audit(target_chapter,
    case when p_approve then 'verification.approved' else 'verification.rejected' end,
    'verification_request', p_request_id::text,
    jsonb_build_object('member', target_user, 'reason', p_reason));
  perform public.create_notification(target_user,
    case when p_approve then 'Account verified' else 'Verification not approved' end,
    case when p_approve then 'You can now register for events and earn points.'
         else coalesce('Reason: ' || p_reason, 'Please resubmit a clearer photo of your school ID.') end,
    'general', 'verification_request', p_request_id);
end;
$$;

-- ---------------------------------------------------------------------
-- 12. Claims (scoped to the applicant's chapter)
-- ---------------------------------------------------------------------
drop policy if exists "application_claims_select_own_or_officer" on public.application_claims;
create policy "application_claims_select_own_or_officer" on public.application_claims
  for select to authenticated
  using (user_id = auth.uid() or public.is_officer_of(public.chapter_of(user_id)));

create or replace function public.review_application_claim(
  p_claim_id uuid,
  p_approve  boolean,
  p_reason   text default null
)
returns void language plpgsql security definer set search_path = public as $$
declare
  claim record;
  claim_chapter uuid;
begin
  select * into claim from public.application_claims
  where id = p_claim_id and status = 'pending'
  for update;

  if claim.id is null then
    raise exception 'Claim not found or already reviewed.';
  end if;

  claim_chapter := public.chapter_of(claim.user_id);
  if not public.is_officer_of(claim_chapter) then
    raise exception 'Only an officer of the member''s chapter can review this claim.' using errcode = '42501';
  end if;
  if claim.user_id = auth.uid() then
    raise exception 'You cannot review your own claim.' using errcode = '42501';
  end if;

  update public.application_claims
  set status = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = case when p_approve then null else p_reason end
  where id = p_claim_id;

  if p_approve then
    insert into public.engagement_logs (user_id, action_type, reference_type, reference_id)
    values (claim.user_id, 'opportunity_apply', 'opportunity', claim.opportunity_id)
    on conflict do nothing;
  end if;

  perform public.write_audit(claim_chapter,
    case when p_approve then 'claim.approved' else 'claim.rejected' end,
    'application_claim', p_claim_id::text,
    jsonb_build_object('member', claim.user_id, 'reason', p_reason));
  perform public.create_notification(claim.user_id,
    case when p_approve then 'Application claim approved (+10 points)' else 'Application claim not approved' end,
    case when p_approve then 'Thanks for applying. Your points were added.'
         else coalesce('Reason: ' || p_reason, 'Please resubmit a clearer proof.') end,
    'general', 'application_claim', p_claim_id);
end;
$$;

create or replace function public.review_application_claims_bulk(
  p_claim_ids uuid[],
  p_approve   boolean,
  p_reason    text default null
)
returns integer language plpgsql security definer set search_path = public as $$
declare
  reviewed integer;
  my_chapter uuid := public.my_chapter_id();
begin
  if not public.is_officer_of(my_chapter) then
    raise exception 'Only officers can review claims.' using errcode = '42501';
  end if;

  with updated as (
    update public.application_claims c
    set status = case when p_approve then 'approved' else 'rejected' end,
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        rejection_reason = case when p_approve then null else p_reason end
    where c.id = any(p_claim_ids)
      and c.status = 'pending'
      and c.user_id <> auth.uid()
      and public.chapter_of(c.user_id) = my_chapter
    returning c.id, c.user_id, c.opportunity_id
  ),
  logged as (
    insert into public.engagement_logs (user_id, action_type, reference_type, reference_id)
    select user_id, 'opportunity_apply', 'opportunity', opportunity_id
    from updated
    where p_approve
    on conflict do nothing
    returning 1
  ),
  notified as (
    insert into public.notifications (user_id, title, body, type, reference_type, reference_id)
    select user_id,
           case when p_approve then 'Application claim approved (+10 points)' else 'Application claim not approved' end,
           case when p_approve then 'Thanks for applying. Your points were added.'
                else coalesce('Reason: ' || p_reason, 'Please resubmit a clearer proof.') end,
           'general', 'application_claim', id
    from updated
    returning 1
  )
  select count(*) into reviewed from updated;

  if reviewed > 0 then
    perform public.write_audit(my_chapter,
      case when p_approve then 'claim.bulk_approved' else 'claim.bulk_rejected' end,
      'application_claim', null,
      jsonb_build_object('count', reviewed, 'requested', coalesce(array_length(p_claim_ids, 1), 0), 'reason', p_reason));
  end if;

  return reviewed;
end;
$$;

-- ---------------------------------------------------------------------
-- 13. Attendance: scoped check-in, undo, no-shows
-- ---------------------------------------------------------------------
create or replace function public.check_in_attendee(
  p_event_id uuid,
  p_qr_code  text default null,
  p_user_id  uuid default null
)
returns text language plpgsql security definer set search_path = public as $$
declare
  reg        record;
  ev         record;
  attendee   text;
begin
  select * into ev from public.events where id = p_event_id;
  if ev.id is null then
    raise exception 'Event not found.';
  end if;

  if not public.is_officer_of(ev.chapter_id) then
    raise exception 'Only officers of this event''s chapter can check attendees in.' using errcode = '42501';
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

  perform set_config('gocollab.system_write', 'on', true);
  update public.event_registrations set status = 'attended' where id = reg.id;

  insert into public.engagement_logs (user_id, action_type, reference_type, reference_id)
  values (reg.user_id, 'event_attend', 'event', p_event_id)
  on conflict do nothing;

  return coalesce(attendee, 'Attendee');
end;
$$;

-- Reverse a wrong check-in: removes the attendance row, restores the
-- registration, and takes back the +25 so a later correct check-in can
-- award it again.
create or replace function public.undo_check_in(p_event_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  ev record;
  removed integer;
  log_removed integer;
begin
  select * into ev from public.events where id = p_event_id;
  if ev.id is null then
    raise exception 'Event not found.';
  end if;
  if not public.is_officer_of(ev.chapter_id) then
    raise exception 'Only officers of this event''s chapter can undo a check-in.' using errcode = '42501';
  end if;

  delete from public.attendance where event_id = p_event_id and user_id = p_user_id;
  get diagnostics removed = row_count;
  if removed = 0 then
    raise exception 'This member is not checked in.';
  end if;

  perform set_config('gocollab.system_write', 'on', true);
  update public.event_registrations set status = 'registered'
  where event_id = p_event_id and user_id = p_user_id and status = 'attended';

  delete from public.engagement_logs
  where user_id = p_user_id and action_type = 'event_attend' and reference_id = p_event_id;
  get diagnostics log_removed = row_count;
  if log_removed > 0 then
    update public.profiles set points = greatest(points - 25, 0) where id = p_user_id;
  end if;

  perform public.write_audit(ev.chapter_id, 'attendance.undone', 'event', p_event_id::text,
    jsonb_build_object('member', p_user_id, 'points_reversed', log_removed > 0));
end;
$$;

-- After an event ends: everyone still just 'registered' becomes 'no-show'.
create or replace function public.mark_no_shows(p_event_id uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  ev record;
  marked integer;
begin
  select * into ev from public.events where id = p_event_id;
  if ev.id is null then
    raise exception 'Event not found.';
  end if;
  if not public.is_officer_of(ev.chapter_id) then
    raise exception 'Only officers of this event''s chapter can mark no-shows.' using errcode = '42501';
  end if;
  if now() < ev.end_at then
    raise exception 'You can mark no-shows after the event has ended.';
  end if;

  perform set_config('gocollab.system_write', 'on', true);
  update public.event_registrations set status = 'no-show'
  where event_id = p_event_id and status = 'registered';
  get diagnostics marked = row_count;

  if marked > 0 then
    perform public.write_audit(ev.chapter_id, 'attendance.no_shows_marked', 'event', p_event_id::text,
      jsonb_build_object('count', marked));
  end if;
  return marked;
end;
$$;

grant execute on function public.undo_check_in(uuid, uuid) to authenticated;
grant execute on function public.mark_no_shows(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 14. Storage: ID photos and proofs are readable only by officers of the
--     owner's chapter (never by officers elsewhere, never by admins).
-- ---------------------------------------------------------------------
drop policy if exists "verification_docs_owner_or_officer_read" on storage.objects;
create policy "verification_docs_owner_or_officer_read" on storage.objects for select to authenticated
  using (
    bucket_id = 'verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text
         or public.is_officer_of(public.storage_owner_chapter(name)))
  );

drop policy if exists "verification_docs_owner_or_officer_delete" on storage.objects;
create policy "verification_docs_owner_or_officer_delete" on storage.objects for delete to authenticated
  using (
    bucket_id = 'verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text
         or public.is_officer_of(public.storage_owner_chapter(name)))
  );

drop policy if exists "application_proofs_owner_or_officer_read" on storage.objects;
create policy "application_proofs_owner_or_officer_read" on storage.objects for select to authenticated
  using (
    bucket_id = 'application-proofs'
    and ((storage.foldername(name))[1] = auth.uid()::text
         or public.is_officer_of(public.storage_owner_chapter(name)))
  );

-- NOTE: `event-banners` is a PUBLIC bucket of promotional images with no
-- personal data, so its officer write policies are intentionally unchanged.

-- ---------------------------------------------------------------------
-- 15. First administrator
-- ---------------------------------------------------------------------
-- Run once in the SQL editor with your own account's email:
--   update public.profiles set role_id = 3 where email = 'you@example.com';
-- (An admin is not tied to a chapter's day-to-day work; keep at least one.)
