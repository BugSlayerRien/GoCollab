-- Public bucket for event banner images uploaded by officers.

insert into storage.buckets (id, name, public)
values ('event-banners', 'event-banners', true)
on conflict (id) do update set public = true;

create policy "event_banners_public_read"
  on storage.objects for select
  using (bucket_id = 'event-banners');

create policy "event_banners_officer_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'event-banners' and public.is_officer());

create policy "event_banners_officer_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'event-banners' and public.is_officer());

create policy "event_banners_officer_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'event-banners' and public.is_officer());
