-- Real Estate CRM SaaS: tenant-aware MVP schema.
-- Run in Supabase SQL Editor. Review this migration before production use.

create extension if not exists pgcrypto;

create type public.platform_role as enum ('user','super_admin');
create type public.agency_role as enum (
  'agency_admin','sales_manager','sales_agent','marketing_manager',
  'marketing_executive','customer_support','accounts_finance',
  'inventory_manager','main_channel_partner','sub_channel_partner'
);
create type public.agency_status as enum ('pending','active','suspended','closed');
create type public.subscription_status as enum (
  'trial','active','payment_pending','past_due','suspended','cancelled','expired'
);
create type public.lead_status as enum (
  'new','contacted','qualified','site_visit','negotiation','won','lost'
);
create type public.lead_source as enum ('website','facebook','referral','walk_in','partner','other');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  platform_role public.platform_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.agencies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  owner_name text,
  business_email text not null,
  phone text,
  country text default 'India',
  state text,
  city text,
  business_address text,
  website text,
  gstin text,
  status public.agency_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.agency_memberships (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.agency_role not null,
  status text not null default 'active' check (status in ('invited','active','disabled')),
  created_at timestamptz not null default now(),
  unique(agency_id,user_id)
);
create index memberships_user_idx on public.agency_memberships(user_id);
create index memberships_agency_idx on public.agency_memberships(agency_id);

create table public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  monthly_price numeric(12,2) not null default 0 check(monthly_price >= 0),
  yearly_price numeric(12,2) not null default 0 check(yearly_price >= 0),
  limits jsonb not null default '{}'::jsonb,
  features jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.agency_subscriptions (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id),
  status public.subscription_status not null default 'trial',
  billing_cycle text not null default 'monthly' check(billing_cycle in ('monthly','quarterly','annual')),
  starts_at timestamptz not null default now(),
  renews_at timestamptz,
  trial_ends_at timestamptz,
  created_at timestamptz not null default now()
);
create index subscriptions_agency_idx on public.agency_subscriptions(agency_id);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  name text not null,
  location text,
  description text,
  status text not null default 'active' check(status in ('active','inactive','completed')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(agency_id,id)
);
create index projects_agency_idx on public.projects(agency_id,created_at desc);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  full_name text not null,
  email text,
  phone text,
  source public.lead_source not null default 'other',
  status public.lead_status not null default 'new',
  assigned_to uuid references public.profiles(id),
  project_id uuid,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (agency_id,project_id) references public.projects(agency_id,id)
);
create index leads_agency_created_idx on public.leads(agency_id,created_at desc);
create index leads_agency_status_idx on public.leads(agency_id,status);

create table public.site_visits (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  lead_id uuid not null,
  project_id uuid not null,
  scheduled_at timestamptz not null,
  status text not null default 'scheduled' check(status in ('scheduled','completed','cancelled','no_show')),
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  foreign key (agency_id,lead_id) references public.leads(agency_id,id),
  foreign key (agency_id,project_id) references public.projects(agency_id,id)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  lead_id uuid not null,
  project_id uuid not null,
  booking_reference text not null,
  amount numeric(14,2) not null default 0 check(amount >= 0),
  status text not null default 'pending' check(status in ('pending','confirmed','cancelled','refunded')),
  booked_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(agency_id,booking_reference),
  foreign key (agency_id,lead_id) references public.leads(agency_id,id),
  foreign key (agency_id,project_id) references public.projects(agency_id,id)
);

create table public.channel_partners (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  user_id uuid references public.profiles(id),
  full_name text not null,
  email text,
  phone text,
  partner_type text not null check(partner_type in ('main','sub')),
  parent_partner_id uuid,
  status text not null default 'active' check(status in ('active','inactive')),
  created_at timestamptz not null default now(),
  unique(agency_id,id),
  foreign key (agency_id,parent_partner_id) references public.channel_partners(agency_id,id)
);

create table public.commission_rules (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  partner_type text not null check(partner_type in ('main','sub')),
  calculation_type text not null check(calculation_type in ('percentage','fixed')),
  rate numeric(12,4) not null check(rate >= 0),
  project_id uuid,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (agency_id,project_id) references public.projects(agency_id,id)
);

create table public.commissions (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  booking_id uuid not null references public.bookings(id),
  partner_id uuid not null,
  applied_rate numeric(12,4) not null,
  calculation_type text not null,
  base_amount numeric(14,2) not null,
  commission_amount numeric(14,2) not null,
  status text not null default 'pending' check(status in ('pending','approved','paid','rejected')),
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (agency_id,partner_id) references public.channel_partners(agency_id,id)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid references public.agencies(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_logs_agency_created_idx on public.audit_logs(agency_id,created_at desc);

-- Security-definer helpers avoid recursive RLS evaluation on memberships/profiles.
create or replace function public.current_agency_ids()
returns setof uuid
language sql stable security definer
set search_path = public
as $$
  select m.agency_id
  from public.agency_memberships m
  join public.agencies a on a.id = m.agency_id
  where m.user_id = auth.uid()
    and m.status = 'active'
    and a.status = 'active'
$$;

create or replace function public.is_platform_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.platform_role = 'super_admin'
  )
$$;

create or replace function public.has_agency_permission(target_agency uuid, required_permission text)
returns boolean
language plpgsql stable security definer
set search_path = public
as $$
declare user_role public.agency_role;
begin
  select role into user_role from public.agency_memberships
  where agency_id = target_agency and user_id = auth.uid() and status = 'active';
  if user_role is null then return false; end if;

  if user_role = 'agency_admin' then return true; end if;

  if required_permission in ('leads.read','projects.read') then
    return user_role in ('sales_manager','sales_agent','marketing_manager',
      'marketing_executive','customer_support','inventory_manager',
      'accounts_finance','main_channel_partner','sub_channel_partner');
  end if;
  if required_permission = 'leads.create' then
    return user_role in ('sales_manager','sales_agent','marketing_manager',
      'marketing_executive','main_channel_partner','sub_channel_partner');
  end if;
  if required_permission = 'projects.create' then
    return user_role in ('inventory_manager','sales_manager');
  end if;
  return false;
end;
$$;

alter table public.profiles enable row level security;
alter table public.agencies enable row level security;
alter table public.agency_memberships enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.agency_subscriptions enable row level security;
alter table public.projects enable row level security;
alter table public.leads enable row level security;
alter table public.site_visits enable row level security;
alter table public.bookings enable row level security;
alter table public.channel_partners enable row level security;
alter table public.commission_rules enable row level security;
alter table public.commissions enable row level security;
alter table public.audit_logs enable row level security;

create policy "profile read self or same agency"
on public.profiles for select to authenticated
using (id = auth.uid() or exists (
  select 1 from public.agency_memberships mine
  join public.agency_memberships theirs on theirs.agency_id = mine.agency_id
  where mine.user_id = auth.uid() and mine.status = 'active'
    and theirs.user_id = profiles.id and theirs.status = 'active'
));
create policy "profile update self"
on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

create policy "agency members can read own agency"
on public.agencies for select to authenticated
using (id in (select public.current_agency_ids()) or public.is_platform_admin());

create policy "members can read own memberships"
on public.agency_memberships for select to authenticated
using (agency_id in (select public.current_agency_ids()) or user_id = auth.uid() or public.is_platform_admin());

create policy "plans readable by authenticated"
on public.subscription_plans for select to authenticated using (is_active = true or public.is_platform_admin());

create policy "members can read own subscription"
on public.agency_subscriptions for select to authenticated
using (agency_id in (select public.current_agency_ids()) or public.is_platform_admin());

create policy "tenant select projects"
on public.projects for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant insert projects"
on public.projects for insert to authenticated
with check (agency_id in (select public.current_agency_ids()) and created_by = auth.uid()
  and public.has_agency_permission(agency_id,'projects.create'));
create policy "tenant update projects"
on public.projects for update to authenticated
using (agency_id in (select public.current_agency_ids())
  and public.has_agency_permission(agency_id,'projects.create'))
with check (agency_id in (select public.current_agency_ids()));
create policy "tenant delete projects"
on public.projects for delete to authenticated
using (agency_id in (select public.current_agency_ids())
  and public.has_agency_permission(agency_id,'projects.create'));

create policy "tenant select leads"
on public.leads for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant insert leads"
on public.leads for insert to authenticated
with check (agency_id in (select public.current_agency_ids()) and created_by = auth.uid()
  and public.has_agency_permission(agency_id,'leads.create'));
create policy "tenant update leads"
on public.leads for update to authenticated
using (agency_id in (select public.current_agency_ids()))
with check (agency_id in (select public.current_agency_ids()));
create policy "tenant delete leads"
on public.leads for delete to authenticated
using (agency_id in (select public.current_agency_ids())
  and public.has_agency_permission(agency_id,'leads.create'));

create policy "tenant select site visits" on public.site_visits for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant manage site visits" on public.site_visits for all to authenticated
using (agency_id in (select public.current_agency_ids()))
with check (agency_id in (select public.current_agency_ids()));

create policy "tenant select bookings" on public.bookings for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant manage bookings" on public.bookings for all to authenticated
using (agency_id in (select public.current_agency_ids()))
with check (agency_id in (select public.current_agency_ids()));

create policy "tenant select partners" on public.channel_partners for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant manage partners" on public.channel_partners for all to authenticated
using (agency_id in (select public.current_agency_ids()))
with check (agency_id in (select public.current_agency_ids()));

create policy "tenant select commission rules" on public.commission_rules for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant manage commission rules" on public.commission_rules for all to authenticated
using (agency_id in (select public.current_agency_ids()))
with check (agency_id in (select public.current_agency_ids()));

create policy "tenant select commissions" on public.commissions for select to authenticated
using (agency_id in (select public.current_agency_ids()));
create policy "tenant manage commissions" on public.commissions for all to authenticated
using (agency_id in (select public.current_agency_ids()))
with check (agency_id in (select public.current_agency_ids()));

create policy "tenant select audit logs" on public.audit_logs for select to authenticated
using (agency_id in (select public.current_agency_ids()) or public.is_platform_admin());
create policy "tenant insert audit logs" on public.audit_logs for insert to authenticated
with check (actor_id = auth.uid() and (agency_id is null or agency_id in (select public.current_agency_ids())));

-- Restrict function execution to authenticated users.
revoke all on function public.current_agency_ids() from public;
revoke all on function public.is_platform_admin() from public;
revoke all on function public.has_agency_permission(uuid,text) from public;
grant execute on function public.current_agency_ids() to authenticated;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.has_agency_permission(uuid,text) to authenticated;

-- Starter plans for development; prices are illustrative and editable.
insert into public.subscription_plans(name,monthly_price,yearly_price,limits,features)
values
('Starter',0,0,
 '{"users":3,"projects":3,"leads":500,"partners":0,"storage_mb":500}'::jsonb,
 '{"leads":true,"projects":true,"pipeline":true,"partners":false,"automation":false}'::jsonb),
('Growth',999,9990,
 '{"users":15,"projects":20,"leads":5000,"partners":50,"storage_mb":5000}'::jsonb,
 '{"leads":true,"projects":true,"pipeline":true,"partners":true,"automation":true}'::jsonb),
('Professional',2499,24990,
 '{"users":50,"projects":100,"leads":25000,"partners":250,"storage_mb":20000}'::jsonb,
 '{"leads":true,"projects":true,"pipeline":true,"partners":true,"automation":true,"advanced_reports":true}'::jsonb)
on conflict (name) do nothing;
