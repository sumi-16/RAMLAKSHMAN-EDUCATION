-- RamLakshman Education: Government Jobs portal
-- Run this script in Supabase SQL Editor. It does not delete or modify existing tables.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_site_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_site_admin() from public;
grant execute on function public.is_site_admin() to anon, authenticated;

create table if not exists public.government_jobs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  organization text not null,
  state text not null default 'Andhra Pradesh',
  category text not null default 'Other',
  notification_no text,
  vacancies integer check (vacancies is null or vacancies >= 0),
  qualification text,
  age_limit text,
  age_relaxation text,
  application_fee text,
  salary text,
  important_dates text,
  selection_process text,
  exam_pattern text,
  syllabus text,
  notification_url text,
  apply_url text,
  status text not null default 'open' check (status in ('open','upcoming','closed')),
  description text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_updates (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.government_jobs(id) on delete cascade,
  update_type text not null check (update_type in ('result','admit_card','answer_key','exam_date','corrigendum','selection')),
  title text not null,
  update_date date,
  document_url text,
  source_url text,
  details text,
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists government_jobs_public_idx
  on public.government_jobs (published, created_at desc);
create index if not exists job_updates_public_idx
  on public.job_updates (published, update_date desc);
create index if not exists job_updates_job_idx on public.job_updates(job_id);

alter table public.admin_users enable row level security;
alter table public.government_jobs enable row level security;
alter table public.job_updates enable row level security;

drop policy if exists "Admins can read admin list" on public.admin_users;
create policy "Admins can read admin list" on public.admin_users
  for select to authenticated using (public.is_site_admin());

drop policy if exists "Public can read published jobs" on public.government_jobs;
create policy "Public can read published jobs" on public.government_jobs
  for select to anon, authenticated using (published = true or public.is_site_admin());

drop policy if exists "Admins can manage jobs" on public.government_jobs;
create policy "Admins can manage jobs" on public.government_jobs
  for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public can read published job updates" on public.job_updates;
create policy "Public can read published job updates" on public.job_updates
  for select to anon, authenticated using (
    published = true or public.is_site_admin()
  );

drop policy if exists "Admins can manage job updates" on public.job_updates;
create policy "Admins can manage job updates" on public.job_updates
  for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

-- ADMIN BOOTSTRAP:
-- 1) Create/sign in to your admin account in Supabase Authentication.
-- 2) Open Authentication -> Users and copy that user's UUID.
-- 3) Replace YOUR_AUTH_USER_UUID below and run this one statement:
-- insert into public.admin_users (user_id) values ('YOUR_AUTH_USER_UUID')
-- on conflict (user_id) do nothing;
-- Never expose the Supabase service_role key in browser code.
