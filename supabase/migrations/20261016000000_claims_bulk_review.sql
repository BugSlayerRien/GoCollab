-- Scaling claim review: OCR hint per proof + bulk approve/reject.

alter table public.application_claims
  add column if not exists ocr_result text not null default 'not_run'
    check (ocr_result in ('not_run', 'matched', 'partial', 'mismatch'));

-- submit_application_proof gains an advisory OCR result. The parameter list
-- changes, so drop the old signature instead of leaving an overload behind.
drop function if exists public.submit_application_proof(uuid, text);

create or replace function public.submit_application_proof(
  p_opportunity_id uuid,
  p_proof_path     text,
  p_ocr_result     text default 'not_run'
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
      rejection_reason = null,
      ocr_result = case when p_ocr_result in ('not_run','matched','partial','mismatch')
                        then p_ocr_result else 'not_run' end
  where user_id = auth.uid()
    and opportunity_id = p_opportunity_id
    and status in ('clicked', 'rejected');

  if not found then
    raise exception 'Tap "Apply now" first, or this claim was already submitted.';
  end if;
end;
$$;

-- Review many claims in one round trip. Skips anything that is no longer
-- pending, so it is safe to retry. Returns how many were actually changed.
create or replace function public.review_application_claims_bulk(
  p_claim_ids uuid[],
  p_approve   boolean,
  p_reason    text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  reviewed integer;
begin
  if not public.is_officer() then
    raise exception 'Only officers can review claims.' using errcode = '42501';
  end if;

  with updated as (
    update public.application_claims
    set status = case when p_approve then 'approved' else 'rejected' end,
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        rejection_reason = case when p_approve then null else p_reason end
    where id = any(p_claim_ids) and status = 'pending'
    returning user_id, opportunity_id
  ),
  logged as (
    insert into public.engagement_logs (user_id, action_type, reference_type, reference_id)
    select user_id, 'opportunity_apply', 'opportunity', opportunity_id
    from updated
    where p_approve
    on conflict do nothing
    returning 1
  )
  select count(*) into reviewed from updated;

  return reviewed;
end;
$$;
