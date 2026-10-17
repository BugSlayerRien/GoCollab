-- GDG community integration + Google tool links on events.

-- Chapters whose events are shown in the in-app "GDG Community" feed.
-- chapter_id is the id used by gdg.community.dev (visible as chapter.id in its
-- public event API). is_own marks the chapter(s) this app belongs to, whose
-- events officers can import into GoCollab.
create table if not exists public.gdg_chapters (
  chapter_id int primary key,
  name       text not null,
  country    text not null default 'PH',
  is_own     boolean not null default false,
  added_by   uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.gdg_chapters enable row level security;

drop policy if exists "gdg_chapters_select_all" on public.gdg_chapters;
create policy "gdg_chapters_select_all" on public.gdg_chapters
  for select to authenticated using (true);

drop policy if exists "gdg_chapters_officer_write" on public.gdg_chapters;
create policy "gdg_chapters_officer_write" on public.gdg_chapters
  for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

insert into public.gdg_chapters (chapter_id, name) values
  (605,  'GDG Manila'),
  (484,  'GDG Cloud Manila'),
  (633,  'GDG Baguio'),
  (2931, 'GDG on Campus National University, Manila'),
  (2848, 'GDG on Campus Pamantasan Ng Lungsod Ng Maynila'),
  (2926, 'GDG on Campus Polytechnic University of the Philippines'),
  (2929, 'GDG on Campus Bicol University - Legazpi City')
on conflict (chapter_id) do nothing;

-- Optional links on an event.
alter table public.events
  add column if not exists gdg_event_url text,
  add column if not exists feedback_form_url text;
