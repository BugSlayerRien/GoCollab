-- =====================================================================
-- GoCollab :: Seed Data
-- Baseline reference data so the app is usable immediately after setup.
-- User-owned rows (profiles, registrations, etc.) are created at runtime
-- once real accounts sign up, and are intentionally left out here.
-- =====================================================================

insert into public.chapters (name, campus, region) values
  ('GDGoC Manila', 'University of Manila', 'NCR'),
  ('GDGoC Cebu', 'University of Cebu', 'Region VII'),
  ('GDGoC Davao', 'University of Davao', 'Region XI')
on conflict do nothing;

insert into public.opportunities (title, organization, type, description, requirements, location, is_remote, application_url, deadline, status) values
  ('Software Engineering Internship', 'Google Philippines', 'internship',
   'Join Google Philippines for a 12-week paid internship building real production features alongside senior engineers.',
   'Currently enrolled in a CS/IT-related program, proficiency in one OOP language, strong problem-solving skills.',
   'Manila, PH', false, 'https://careers.google.com', now() + interval '30 days', 'open'),
  ('DOST-SEI Merit Scholarship', 'DOST Science Education Institute', 'scholarship',
   'Full scholarship covering tuition, stipend, and book allowance for outstanding STEM students.',
   'Filipino citizen, top 5% of graduating class, taking up a priority STEM course.',
   'Nationwide', true, 'https://www.sei.dost.gov.ph', now() + interval '45 days', 'open'),
  ('Google Cloud Associate Engineer Certification', 'Google Cloud', 'certification',
   'Prepare and get certified as a Google Cloud Associate Engineer with GDGoC-sponsored exam vouchers.',
   'Basic cloud computing knowledge recommended.',
   'Online', true, 'https://cloud.google.com/certification', now() + interval '60 days', 'open'),
  ('GDGoC Philippines Nationwide Hackathon', 'Google Developer Groups on Campus', 'hackathon',
   'A 24-hour nationwide hackathon focused on building solutions for the UN SDGs.',
   'Open to all GDGoC members, teams of 2-4.',
   'Multiple campuses', false, 'https://gdg.community.dev', now() + interval '20 days', 'open')
on conflict do nothing;

insert into public.events (title, description, category, venue_name, venue_address, latitude, longitude, is_online, start_at, end_at, capacity, registration_deadline, is_featured, status) values
  ('Flutter Forward: Building Beautiful Apps', 'A hands-on workshop covering Material Design 3, Riverpod, and clean architecture in Flutter.',
   'workshop', 'GDGoC Manila Innovation Hub', '123 Taft Ave, Manila', 14.5764, 120.9936, false,
   now() + interval '7 days', now() + interval '7 days 3 hours', 120, now() + interval '5 days', true, 'upcoming'),
  ('Cloud Study Jam: Google Cloud Fundamentals', 'Guided self-paced labs on Google Cloud, with mentors on standby.',
   'study-jam', 'Online via Google Meet', null, null, null, true,
   now() + interval '3 days', now() + interval '3 days 2 hours', 300, now() + interval '2 days', true, 'upcoming'),
  ('GDGoC Philippines DevFest 2026', 'The flagship annual developer festival featuring keynote speakers from Google.',
   'meetup', 'SMX Convention Center', 'Mall of Asia Complex, Pasay City', 14.5352, 120.9829, false,
   now() + interval '14 days', now() + interval '14 days 8 hours', 500, now() + interval '10 days', true, 'upcoming')
on conflict do nothing;

insert into public.announcements (title, body, category, is_pinned, published_at) values
  ('Welcome to GoCollab!', 'We are thrilled to launch GoCollab, the new home for all GDGoC Philippines community activities. Explore events, career opportunities, and more.',
   'general', true, now() - interval '1 day'),
  ('DevFest 2026 Registration is Now Open', 'Registration for GDGoC Philippines DevFest 2026 is now live. Secure your slot before seats run out!',
   'event', true, now() - interval '2 hours'),
  ('New Career Opportunities Added', 'Check out the latest internship, scholarship, and certification opportunities added to the Career Hub this week.',
   'career', false, now() - interval '5 hours')
on conflict do nothing;

insert into public.partners (name, category, description, contact_person, contact_email, address, latitude, longitude, website, collaboration_status) values
  ('Google Philippines', 'industry', 'Official technology partner supporting GDGoC nationwide programs.',
   'Partnerships Team', 'partnerships@google.com', 'Bonifacio Global City, Taguig', 14.5508, 121.0509, 'https://google.com.ph', 'active'),
  ('DOST-SEI', 'government', 'Government partner providing scholarship pipelines for STEM students.',
   'Scholarship Office', 'info@sei.dost.gov.ph', 'Taguig City', 14.5473, 121.0508, 'https://sei.dost.gov.ph', 'active'),
  ('TechStart PH', 'startup', 'Local startup accelerator collaborating on hackathon mentorship.',
   'Community Lead', 'hello@techstart.ph', 'Cebu City', 10.3157, 123.8854, 'https://techstart.ph', 'prospect')
on conflict do nothing;
