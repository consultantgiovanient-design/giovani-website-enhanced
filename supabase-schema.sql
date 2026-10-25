-- Run once in Supabase: SQL Editor -> New query -> paste -> Run.
create table if not exists subscribers (
  email text primary key,                       -- store in lowercase
  tier text not null default 'Free',            -- Free | Professional | Enterprise
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists enquiries (
  id uuid primary key default gen_random_uuid(),
  type text, name text not null, organization text,
  email text not null, phone text, interest text,
  created_at timestamptz not null default now()
);

create table if not exists design_requests (
  id uuid primary key default gen_random_uuid(),
  project_type text, location text, style text, render_mode text,
  brief text, email text, provider text,
  storage_path text, status text default 'generated',
  created_at timestamptz not null default now()
);

-- Lock the tables: only the server (service role key) can read or write.
alter table subscribers enable row level security;
alter table enquiries enable row level security;
alter table design_requests enable row level security;

-- Private storage bucket for concept sketches.
insert into storage.buckets (id, name, public)
values ('design-sketches', 'design-sketches', false)
on conflict (id) do nothing;
