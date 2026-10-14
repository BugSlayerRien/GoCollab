-- Result of the on-device OCR scan of the submitted school ID, shown to the
-- reviewing officer as a hint. It is produced by the member's own device, so
-- it is advisory only — the officer's decision is what verifies the account.
alter table public.verification_requests
  add column if not exists ocr_result text not null default 'not_run'
    check (ocr_result in ('not_run', 'matched', 'partial', 'mismatch'));
