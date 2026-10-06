-- Private bucket for student ID photos submitted for verification.
--
-- Unlike `avatars` and `event-banners`, this bucket is NOT public: the files
-- are government/school identity documents. Members can only write into (and
-- read back) their own `<user-id>/` folder; officers can read everything so
-- they can review the queue. Officer review reads these through short-lived
-- signed URLs — there are no public URLs for this bucket.

insert into storage.buckets (id, name, public)
values ('verification-docs', 'verification-docs', false)
on conflict (id) do update set public = false;

drop policy if exists "verification_docs_owner_or_officer_read" on storage.objects;
create policy "verification_docs_owner_or_officer_read"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_officer())
  );

drop policy if exists "verification_docs_owner_insert" on storage.objects;
create policy "verification_docs_owner_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "verification_docs_owner_update" on storage.objects;
create policy "verification_docs_owner_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "verification_docs_owner_or_officer_delete" on storage.objects;
create policy "verification_docs_owner_or_officer_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_officer())
  );
