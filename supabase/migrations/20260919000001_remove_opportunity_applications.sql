-- Reverts 20260904000000_opportunity_applications.sql: the self-report
-- "Mark as applied" feature is removed from the app. Drops the table and
-- restores engagement_logs to its pre-apply-tracking shape.

drop table if exists public.opportunity_applications;

alter table public.engagement_logs drop constraint if exists engagement_logs_action_type_check;
alter table public.engagement_logs add constraint engagement_logs_action_type_check
  check (action_type in ('login','event_view','event_register','event_attend',
                          'opportunity_view','opportunity_save',
                          'announcement_view','profile_update','certificate_earned'));

drop index if exists public.engagement_logs_unique_pointable_action;
create unique index engagement_logs_unique_pointable_action
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
