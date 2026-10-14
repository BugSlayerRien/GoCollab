-- =====================================================================
-- Redeeming points for applying on an EXTERNAL site
-- =====================================================================
-- GoCollab can't see what happens on a partner's website, so points for an
-- external application are only released after three server-recorded steps:
--   1. 'clicked'  — the member tapped "Apply now" (timestamped by the DB)
--   2. 'pending'  — the member uploaded proof (screenshot of the
--                   confirmation page / email) from that same account
--   3. 'approved' — an officer looked at the proof and accepted it
-- Only step 3 awards points, and only the officer RPC can do it.

-- ---------------------------------------------------------------------
-- engagement_logs: allow the 'opportunity_apply' action + award points
-- ---------------------------------------------------------------------
alter table public.engagement_logs drop constraint if exists engagement_logs_action_type_check;
alter table public.engagement_logs add constraint engagement_logs_action_type_check
  check (action_type in ('login','event_view','event_register','event_attend',
                          'opportunity_view','opportunity_save','opportunity_apply',
                          'announcement_view','profile_update','certificate_earned'));

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
    when 'opportunity_apply' then 10
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

-- ---------------------------------------------------------------------
-- Claims table
-- ---------------------------------------------------------------------
create table if not exists public.application_claims (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  opportunity_id   uuid not null references public.opportunities (id) on delete cascade,
  status           text not null default 'clicked'
                   check (status in ('clicked', 'pending', 'approved', 'rejected')),
  clicked_at       timestamptz not null default now(),
  proof_path       text,
  submitted_at     timestamptz,
  reviewed_by      uuid references public.profiles (id) on delete set null,
  reviewed_at      timestamptz,
  rejection_reason text,
  unique (user_id, opportunity_id)
);

create index if not exists application_claims_status_idx on public.application_claims (status);

alter table public.application_claims enable row level security;

drop policy if exists "application_claims_select_own_or_officer" on public.application_claims;
create policy "application_claims_select_own_or_officer" on public.application_claims
  for select to authenticated
  using (user_id = auth.uid() or public.is_officer());

-- Members may only create the initial 'clicked' row. Everything after that
-- goes through the RPCs below, so a member can never set their own status.
drop policy if exists "application_claims_insert_own_click" on public.application_claims;
create policy "application_claims_insert_own_click" on public.application_claims
  for insert to authenticated
  with check (user_id = auth.uid() and status = 'clicked' and proof_path is null);

-- ---------------------------------------------------------------------
-- Member: attach proof (clicked/rejected -> pending)
-- ---------------------------------------------------------------------
create or replace function public.submit_application_proof(
  p_opportunity_id uuid,
  p_proof_path     text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in first.' using errcode = '42501';
  end if;
  if not public.is_verified() then
    raise exception 'Verify your account before claiming points.' using errcode = '42501';
  end if;
  if split_part(p_proof_path, '/', 1) <> auth.uid()::text then
    raise exception 'Invalid proof file.';
  end if;

  update public.application_claims
  set status = 'pending',
      proof_path = p_proof_path,
      submitted_at = now(),
      rejection_reason = null
  where user_id = auth.uid()
    and opportunity_id = p_opportunity_id
    and status in ('clicked', 'rejected');

  if not found then
    raise exception 'Tap "Apply now" first, or this claim was already submitted.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Officer: approve / reject. Approval is the ONLY place points are released.
-- ---------------------------------------------------------------------
create or replace function public.review_application_claim(
  p_claim_id uuid,
  p_approve  boolean,
  p_reason   text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  claim record;
begin
  if not public.is_officer() then
    raise exception 'Only officers can review claims.' using errcode = '42501';
  end if;

  select * into claim from public.application_claims
  where id = p_claim_id and status = 'pending'
  for update;

  if claim.id is null then
    raise exception 'Claim not found or already reviewed.';
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
end;
$$;

-- ---------------------------------------------------------------------
-- Private bucket for proof screenshots
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('application-proofs', 'application-proofs', false)
on conflict (id) do update set public = false;

drop policy if exists "application_proofs_owner_or_officer_read" on storage.objects;
create policy "application_proofs_owner_or_officer_read"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'application-proofs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_officer())
  );

drop policy if exists "application_proofs_owner_insert" on storage.objects;
create policy "application_proofs_owner_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'application-proofs' and (storage.foldername(name))[1] = auth.uid()::text);
