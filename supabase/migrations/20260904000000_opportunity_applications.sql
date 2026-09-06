-- Self-reported "I applied" tracking for opportunities that route to an
-- external application_url. GoCollab has no way to verify an action taken on
-- a third-party site, so this mirrors the same honesty model already used
-- for events: registration is a self-report, attendance is officer-verified.
-- Here, "applied" is a self-report the member controls, and officers get a
-- visible applicant list (with an optional confirmation note) so they can
-- manually cross-check with the partner organization if needed.

alter table public.engagement_logs drop constraint if exists engagement_logs_action_type_check;
alter table public.engagement_logs add constraint engagement_logs_action_type_check
  check (action_type in ('login','event_view','event_register','event_attend',
                          'opportunity_view','opportunity_save','opportunity_apply',
                          'announcement_view','profile_update','certificate_earned'));

create table if not exists public.opportunity_applications (
  id             uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.opportunities (id) on delete cascade,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  note           text,
  applied_at     timestamptz not null default now(),
  unique (opportunity_id, user_id)
);

create index if not exists opportunity_applications_opportunity_idx
  on public.opportunity_applications (opportunity_id);
create index if not exists opportunity_applications_user_idx
  on public.opportunity_applications (user_id);

alter table public.opportunity_applications enable row level security;

create policy "opportunity_applications_select_own_or_officer" on public.opportunity_applications
  for select to authenticated
  using (user_id = auth.uid() or public.is_officer());
create policy "opportunity_applications_insert_own" on public.opportunity_applications
  for insert to authenticated
  with check (user_id = auth.uid());
create policy "opportunity_applications_upsert_own" on public.opportunity_applications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "opportunity_applications_delete_own_or_officer" on public.opportunity_applications
  for delete to authenticated
  using (user_id = auth.uid() or public.is_officer());

-- Extend the pointable-action allowlist to include opportunity_apply, awarded
-- once per user + opportunity just like event_register.
drop index if exists public.engagement_logs_unique_pointable_action;
create unique index engagement_logs_unique_pointable_action
  on public.engagement_logs (user_id, action_type, reference_id)
  where reference_id is not null
    and action_type in (
      'opportunity_save',
      'opportunity_apply',
      'event_register',
      'event_attend',
      'certificate_earned'
    );

create or replace function public.award_engagement_points()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  delta integer;
  already_awarded boolean;
begin
  if new.reference_id is not null
     and new.action_type in (
       'opportunity_save',
       'opportunity_apply',
       'event_register',
       'event_attend',
       'certificate_earned'
     ) then
    select exists (
      select 1
      from public.engagement_logs el
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
    when 'opportunity_apply' then 5
    when 'certificate_earned' then 50
    when 'profile_update' then 2
    else 1
  end;

  update public.profiles
  set points = points + delta
  where id = new.user_id;

  return new;
end;
$$;
