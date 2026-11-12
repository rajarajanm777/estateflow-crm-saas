-- EstateFlow phases 1-5: extended SaaS, operations, marketing, billing and analytics foundation.
-- Safe additive migration. Existing lead, project, booking, partner and automation data is preserved.
create extension if not exists pgcrypto;

create table if not exists public.follow_up_tasks (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 lead_id uuid, title text not null, description text, due_at timestamptz, priority text not null default 'normal' check(priority in ('low','normal','high')),
 status text not null default 'open' check(status in ('open','in_progress','completed','cancelled')),
 assigned_to uuid references public.profiles(id), created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 foreign key(agency_id,lead_id) references public.leads(agency_id,id)
);
create index if not exists follow_up_tasks_agency_due_idx on public.follow_up_tasks(agency_id,due_at);

create table if not exists public.inventory_units (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 project_id uuid not null, unit_code text not null, unit_type text, area_sqft numeric(12,2), price numeric(14,2) not null default 0,
 status text not null default 'available' check(status in ('available','blocked','reserved','sold')),
 notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(agency_id,unit_code), foreign key(agency_id,project_id) references public.projects(agency_id,id)
);

create table if not exists public.marketing_campaigns (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 name text not null, channel text not null default 'email' check(channel in ('email','whatsapp','sms','social','other')),
 status text not null default 'draft' check(status in ('draft','scheduled','active','paused','completed')),
 starts_at timestamptz, ends_at timestamptz, budget numeric(14,2) not null default 0, content text,
 created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.agency_integrations (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 provider text not null, display_name text not null, status text not null default 'not_connected' check(status in ('not_connected','pending','connected','error','disabled')),
 config jsonb not null default '{}'::jsonb, credentials_ref text, last_checked_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(agency_id,provider)
);

create table if not exists public.invoices (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 subscription_id uuid references public.agency_subscriptions(id) on delete set null, invoice_number text not null,
 amount numeric(14,2) not null check(amount>=0), currency text not null default 'INR', status text not null default 'draft' check(status in ('draft','open','paid','void','overdue')),
 issued_at timestamptz, due_at timestamptz, paid_at timestamptz, provider_invoice_id text, created_at timestamptz not null default now(), unique(agency_id,invoice_number)
);

create table if not exists public.payment_events (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 invoice_id uuid references public.invoices(id) on delete set null, provider text not null, provider_event_id text,
 amount numeric(14,2) not null default 0, currency text not null default 'INR', status text not null default 'pending', payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), unique(provider,provider_event_id)
);

create table if not exists public.usage_events (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 metric text not null, quantity numeric(14,2) not null default 1, source text, occurred_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb
);
create index if not exists usage_events_agency_time_idx on public.usage_events(agency_id,occurred_at desc);

create table if not exists public.agency_domains (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 domain text not null unique, verification_status text not null default 'pending' check(verification_status in ('pending','verified','failed')),
 ssl_status text not null default 'pending', is_primary boolean not null default false, created_at timestamptz not null default now()
);

create table if not exists public.landing_pages (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 title text not null, slug text not null, status text not null default 'draft' check(status in ('draft','published','archived')),
 form_config jsonb not null default '{}'::jsonb, content jsonb not null default '{}'::jsonb, created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(agency_id,slug)
);

create table if not exists public.notification_logs (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 channel text not null check(channel in ('email','whatsapp','sms','call','in_app')), recipient text, template_key text,
 status text not null default 'queued' check(status in ('queued','sent','delivered','failed')),
 provider_message_id text, error_message text, sent_at timestamptz, created_at timestamptz not null default now()
);

create table if not exists public.automation_executions (
 id uuid primary key default gen_random_uuid(), agency_id uuid not null references public.agencies(id) on delete cascade,
 workflow_id uuid references public.automation_workflows(id) on delete set null, trigger_event text not null,
 status text not null default 'queued' check(status in ('queued','running','succeeded','failed','retrying')),
 attempts integer not null default 0, input jsonb not null default '{}'::jsonb, output jsonb not null default '{}'::jsonb,
 error_message text, started_at timestamptz, finished_at timestamptz, created_at timestamptz not null default now()
);

create table if not exists public.platform_support_requests (
 id uuid primary key default gen_random_uuid(), agency_id uuid references public.agencies(id) on delete cascade,
 requested_by uuid references public.profiles(id), subject text not null, description text, status text not null default 'open' check(status in ('open','in_progress','resolved','closed')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

-- Enable tenant/platform RLS on all added tables.
do $$ declare t text; begin
 foreach t in array array['follow_up_tasks','inventory_units','marketing_campaigns','agency_integrations','invoices','payment_events','usage_events','agency_domains','landing_pages','notification_logs','automation_executions','platform_support_requests'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('drop policy if exists %I on public.%I',t||'_tenant_read',t);
  execute format('create policy %I on public.%I for select to authenticated using (agency_id in (select public.current_agency_ids()) or public.is_platform_admin())',t||'_tenant_read',t);
  execute format('drop policy if exists %I on public.%I',t||'_tenant_write',t);
  execute format('create policy %I on public.%I for all to authenticated using (agency_id in (select public.current_agency_ids()) or public.is_platform_admin()) with check (agency_id in (select public.current_agency_ids()) or public.is_platform_admin())',t||'_tenant_write',t);
 end loop;
end $$;

-- Platform owners can manage platform-level agency and plan records. Normal users remain tenant-scoped.
drop policy if exists "platform admins manage agencies" on public.agencies;
create policy "platform admins manage agencies" on public.agencies for all to authenticated using (public.is_platform_admin()) with check (public.is_platform_admin());
drop policy if exists "platform admins manage plans" on public.subscription_plans;
create policy "platform admins manage plans" on public.subscription_plans for all to authenticated using (public.is_platform_admin()) with check (public.is_platform_admin());
drop policy if exists "platform admins manage subscriptions" on public.agency_subscriptions;
create policy "platform admins manage subscriptions" on public.agency_subscriptions for all to authenticated using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Read-only aggregate view for usage dashboards; still tenant filtered by RLS on source table.
create or replace view public.agency_usage_summary with (security_invoker = true) as
 select agency_id, metric, coalesce(sum(quantity),0) as total_quantity,
        date_trunc('month', now()) as period_start
 from public.usage_events where occurred_at >= date_trunc('month',now())
 group by agency_id,metric;

comment on table public.agency_integrations is 'Stores integration metadata only. Keep provider secrets in a secure server-side secret store; never put raw tokens in config.';
comment on table public.payment_events is 'Payment provider webhook event ledger. Verify webhook signatures in a server endpoint before inserting events.';
comment on table public.automation_executions is 'Execution ledger for a separately deployed background worker/queue.';

-- Tighten write permissions for the additive tables: ordinary members may read their tenant,
-- but only managers/admins may mutate operational and billing configuration records.
create or replace function public.is_agency_manager(target_agency uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.agency_memberships m where m.agency_id=target_agency and m.user_id=auth.uid() and m.status='active'
 and m.role in ('agency_admin','sales_manager','marketing_manager','inventory_manager','accounts_finance')) or public.is_platform_admin()
$$;

do $$ declare t text; begin
 foreach t in array array['follow_up_tasks','inventory_units','marketing_campaigns','agency_integrations','invoices','payment_events','usage_events','agency_domains','landing_pages','notification_logs','automation_executions','platform_support_requests'] loop
  execute format('drop policy if exists %I on public.%I',t||'_tenant_write',t);
  execute format('create policy %I on public.%I for all to authenticated using (public.is_agency_manager(agency_id)) with check (public.is_agency_manager(agency_id))',t||'_tenant_write',t);
 end loop;
end $$;

-- Ensure profiles are created for new Auth users.
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,email,full_name) values(new.id,coalesce(new.email,''),coalesce(new.raw_user_meta_data->>'full_name',''))
 on conflict(id) do update set email=excluded.email;
 return new;
end $$;
drop trigger if exists on_auth_user_created_estateflow on auth.users;
create trigger on_auth_user_created_estateflow after insert on auth.users for each row execute procedure public.handle_new_auth_user();

-- Self-service agency creation for an authenticated user; creator becomes agency admin.
create or replace function public.create_agency_workspace(agency_name text,business_email text,agency_city text default null,agency_state text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare new_agency_id uuid; base_slug text; final_slug text;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if length(trim(coalesce(agency_name,''))) < 2 then raise exception 'Agency name is required'; end if;
 if length(trim(coalesce(business_email,''))) < 5 then raise exception 'Business email is required'; end if;
 insert into public.profiles(id,email) select auth.uid(),coalesce((select email from auth.users where id=auth.uid()),'') on conflict(id) do nothing;
 base_slug:=trim(both '-' from regexp_replace(lower(trim(agency_name)),'[^a-z0-9]+','-','g'));
 final_slug:=left(base_slug,40)||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);
 insert into public.agencies(name,slug,business_email,city,state,status) values(trim(agency_name),final_slug,trim(business_email),nullif(trim(agency_city),''),nullif(trim(agency_state),''),'active') returning id into new_agency_id;
 insert into public.agency_memberships(agency_id,user_id,role,status) values(new_agency_id,auth.uid(),'agency_admin','active');
 insert into public.agency_subscriptions(agency_id,plan_id,status,billing_cycle,trial_ends_at)
 select new_agency_id,id,'trial','monthly',now()+interval '14 days' from public.subscription_plans where name='Starter' limit 1;
 return new_agency_id;
end $$;

-- Agency admins can update roles only within their own workspace.
create or replace function public.set_agency_member_role(target_agency uuid,target_user uuid,target_role public.agency_role)
returns void language plpgsql security definer set search_path=public as $$
begin
 if not exists(select 1 from public.agency_memberships where agency_id=target_agency and user_id=auth.uid() and role='agency_admin' and status='active') and not public.is_platform_admin() then
  raise exception 'Only agency admins can change member roles';
 end if;
 update public.agency_memberships set role=target_role where agency_id=target_agency and user_id=target_user;
 if not found then raise exception 'Membership not found'; end if;
end $$;
revoke all on function public.is_agency_manager(uuid) from public;
revoke all on function public.create_agency_workspace(text,text,text,text) from public;
revoke all on function public.set_agency_member_role(uuid,uuid,public.agency_role) from public;
grant execute on function public.is_agency_manager(uuid) to authenticated;
grant execute on function public.create_agency_workspace(text,text,text,text) to authenticated;
grant execute on function public.set_agency_member_role(uuid,uuid,public.agency_role) to authenticated;

-- Commission calculation uses the most specific active rule (project-specific before agency default).
create or replace function public.create_booking_commission(target_booking uuid,target_partner uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare b public.bookings%rowtype; p public.channel_partners%rowtype; r public.commission_rules%rowtype; new_id uuid; amount_value numeric(14,2);
begin
 select * into b from public.bookings where id=target_booking;
 if not found then raise exception 'Booking not found'; end if;
 if not public.is_agency_manager(b.agency_id) then raise exception 'Permission denied'; end if;
 select * into p from public.channel_partners where id=target_partner and agency_id=b.agency_id;
 if not found then raise exception 'Partner not found in this agency'; end if;
 select * into r from public.commission_rules where agency_id=b.agency_id and partner_type=p.partner_type and is_active=true and (project_id=b.project_id or project_id is null)
 order by (project_id is not null) desc, created_at desc limit 1;
 if not found then raise exception 'No active commission rule exists for this partner and project'; end if;
 amount_value:=case when r.calculation_type='percentage' then round(b.amount*r.rate/100,2) else r.rate end;
 insert into public.commissions(agency_id,booking_id,partner_id,applied_rate,calculation_type,base_amount,commission_amount,status)
 values(b.agency_id,b.id,p.id,r.rate,r.calculation_type,b.amount,amount_value,'pending') returning id into new_id;
 return new_id;
end $$;
revoke all on function public.create_booking_commission(uuid,uuid) from public;
grant execute on function public.create_booking_commission(uuid,uuid) to authenticated;

create or replace function public.set_agency_member_role(target_agency uuid,target_user uuid,target_role public.agency_role)
returns void language plpgsql security definer set search_path=public as $$
declare current_admin_count integer;
begin
 if not exists(select 1 from public.agency_memberships where agency_id=target_agency and user_id=auth.uid() and role='agency_admin' and status='active') and not public.is_platform_admin() then
  raise exception 'Only agency admins can change member roles';
 end if;
 if target_user=auth.uid() and not public.is_platform_admin() then raise exception 'You cannot change your own role'; end if;
 if exists(select 1 from public.agency_memberships where agency_id=target_agency and user_id=target_user and role='agency_admin' and status='active') and target_role<>'agency_admin' then
  select count(*) into current_admin_count from public.agency_memberships where agency_id=target_agency and role='agency_admin' and status='active';
  if current_admin_count<=1 then raise exception 'An agency must keep at least one active admin'; end if;
 end if;
 update public.agency_memberships set role=target_role where agency_id=target_agency and user_id=target_user;
 if not found then raise exception 'Membership not found'; end if;
end $$;

-- Enforce role-aware write policies on legacy operational tables (replace permissive MVP policies).
create or replace function public.has_agency_role(target_agency uuid, allowed_roles public.agency_role[])
returns boolean language sql stable security definer set search_path=public as $$
 select public.is_platform_admin() or exists(select 1 from public.agency_memberships m where m.agency_id=target_agency and m.user_id=auth.uid() and m.status='active' and m.role=any(allowed_roles))
$$;
revoke all on function public.has_agency_role(uuid,public.agency_role[]) from public;
grant execute on function public.has_agency_role(uuid,public.agency_role[]) to authenticated;

drop policy if exists "tenant manage site visits" on public.site_visits;
create policy "tenant manage site visits" on public.site_visits for all to authenticated
using (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','sales_agent','customer_support']::public.agency_role[]))
with check (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','sales_agent','customer_support']::public.agency_role[]));

drop policy if exists "tenant manage bookings" on public.bookings;
create policy "tenant manage bookings" on public.bookings for all to authenticated
using (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','accounts_finance']::public.agency_role[]))
with check (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','accounts_finance']::public.agency_role[]));

drop policy if exists "tenant manage partners" on public.channel_partners;
create policy "tenant manage partners" on public.channel_partners for all to authenticated
using (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','main_channel_partner']::public.agency_role[]))
with check (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','main_channel_partner']::public.agency_role[]));

drop policy if exists "tenant manage commission rules" on public.commission_rules;
create policy "tenant manage commission rules" on public.commission_rules for all to authenticated
using (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','accounts_finance']::public.agency_role[]))
with check (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','accounts_finance']::public.agency_role[]));

drop policy if exists "tenant manage commissions" on public.commissions;
create policy "tenant manage commissions" on public.commissions for all to authenticated
using (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','accounts_finance']::public.agency_role[]))
with check (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','accounts_finance']::public.agency_role[]));

drop policy if exists "follow_up_tasks_tenant_write" on public.follow_up_tasks;
create policy "follow_up_tasks_tenant_write" on public.follow_up_tasks for all to authenticated
using (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','sales_agent','marketing_manager']::public.agency_role[]))
with check (agency_id in (select public.current_agency_ids()) and public.has_agency_role(agency_id,array['agency_admin','sales_manager','sales_agent','marketing_manager']::public.agency_role[]));
