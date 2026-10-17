-- =====================================================================
-- Certificates of attendance
-- =====================================================================
-- An officer of the event's chapter issues certificates for everyone who was
-- actually checked in. The certificate record is the source of truth (number,
-- issuer, date); the PDF itself is drawn on the member's device from it, so no
-- file storage is needed. Issuing awards the +50 `certificate_earned` points
-- once per member per event.

create or replace function public.issue_certificates(p_event_id uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  ev record;
  issued integer := 0;
  att record;
begin
  select * into ev from public.events where id = p_event_id;
  if ev.id is null then
    raise exception 'Event not found.';
  end if;
  if not public.is_officer_of(ev.chapter_id) then
    raise exception 'Only officers of this event''s chapter can issue certificates.' using errcode = '42501';
  end if;
  if now() < ev.end_at then
    raise exception 'Certificates can be issued after the event has ended.';
  end if;

  for att in
    select a.user_id from public.attendance a
    where a.event_id = p_event_id
      and not exists (select 1 from public.certificates c where c.event_id = p_event_id and c.user_id = a.user_id)
  loop
    insert into public.certificates (event_id, user_id, certificate_number, issued_by)
    values (
      p_event_id, att.user_id,
      'GC-' || to_char(now(), 'YYYY') || '-' || upper(substr(encode(gen_random_bytes(5), 'hex'), 1, 8)),
      auth.uid()
    );

    insert into public.engagement_logs (user_id, action_type, reference_type, reference_id)
    values (att.user_id, 'certificate_earned', 'event', p_event_id)
    on conflict do nothing;

    perform public.create_notification(att.user_id, 'Certificate ready',
      format('Your certificate for %s is ready. Open your profile to download it.', ev.title),
      'general', 'event', p_event_id);

    issued := issued + 1;
  end loop;

  if issued > 0 then
    perform public.write_audit(ev.chapter_id, 'certificates.issued', 'event', p_event_id::text,
      jsonb_build_object('count', issued));
  end if;
  return issued;
end;
$$;

grant execute on function public.issue_certificates(uuid) to authenticated;
