-- Award community points for engagement, with idempotent rules so members
-- cannot farm points by save/unsave or register/cancel loops.

-- If duplicates already exist (e.g. from dev testing), keep the earliest log
-- per user + action + target so the unique index below can be applied safely.
delete from public.engagement_logs el
where el.reference_id is not null
  and el.action_type in (
    'opportunity_save',
    'event_register',
    'event_attend',
    'certificate_earned'
  )
  and el.id not in (
    select distinct on (user_id, action_type, reference_id) id
    from public.engagement_logs
    where reference_id is not null
      and action_type in (
        'opportunity_save',
        'event_register',
        'event_attend',
        'certificate_earned'
      )
    order by user_id, action_type, reference_id, created_at
  );

-- One engagement log per (user, action, target) for point-earning actions.
-- Re-saving or re-registering hits this constraint; the app treats insert
-- failures as non-fatal so bookmarks/registrations still succeed.
create unique index if not exists engagement_logs_unique_pointable_action
  on public.engagement_logs (user_id, action_type, reference_id)
  where reference_id is not null
    and action_type in (
      'opportunity_save',
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
  -- Point-earning actions tied to a specific resource are awarded at most once
  -- per user, even if duplicate logs somehow exist before the unique index.
  if new.reference_id is not null
     and new.action_type in (
       'opportunity_save',
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

drop trigger if exists engagement_logs_award_points on public.engagement_logs;
create trigger engagement_logs_award_points
after insert on public.engagement_logs
for each row execute function public.award_engagement_points();

-- Backfill: count each pointable action once per user + target (not per log row).
update public.profiles p
set points = coalesce((
  select sum(scored.delta)::integer
  from (
    select distinct on (el.user_id, el.action_type, el.reference_id)
      case el.action_type
        when 'event_register' then 5
        when 'event_attend' then 25
        when 'opportunity_save' then 1
        when 'certificate_earned' then 50
        else 0
      end as delta
    from public.engagement_logs el
    where el.user_id = p.id
      and el.reference_id is not null
      and el.action_type in (
        'opportunity_save',
        'event_register',
        'event_attend',
        'certificate_earned'
      )
    order by el.user_id, el.action_type, el.reference_id, el.created_at
  ) scored
), 0)
+ coalesce((
  select sum(
    case el.action_type
      when 'profile_update' then 2
      else 1
    end
  )::integer
  from public.engagement_logs el
  where el.user_id = p.id
    and (
      el.reference_id is null
      or el.action_type not in (
        'opportunity_save',
        'event_register',
        'event_attend',
        'certificate_earned'
      )
    )
), 0);
