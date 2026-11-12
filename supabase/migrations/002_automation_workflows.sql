-- EstateFlow automation definitions (phase 1: builder + saved workflows)
create table if not exists public.automation_workflows (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  created_by uuid references public.profiles(id) on delete set null,
  name text not null check (char_length(name) between 3 and 120),
  trigger_type text not null check (trigger_type in ('lead_created','lead_status_changed','site_visit_scheduled')),
  condition_config jsonb not null default '{"field":"any","value":""}'::jsonb,
  action_type text not null check (action_type in ('assign_to_admin','create_followup_task','send_email_notice')),
  action_config jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check (status in ('draft','active','paused')),
  enrolled_count integer not null default 0 check (enrolled_count >= 0),
  active_count integer not null default 0 check (active_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (agency_id,id)
);
create index if not exists automation_workflows_agency_updated_idx
  on public.automation_workflows (agency_id, updated_at desc);
alter table public.automation_workflows enable row level security;
drop policy if exists "agency members can read automation workflows" on public.automation_workflows;
create policy "agency members can read automation workflows"
on public.automation_workflows for select to authenticated
using (agency_id in (select public.current_agency_ids()));
drop policy if exists "automation managers can create workflows" on public.automation_workflows;
create policy "automation managers can create workflows"
on public.automation_workflows for insert to authenticated
with check (
  agency_id in (select public.current_agency_ids())
  and exists (select 1 from public.agency_memberships m
    where m.agency_id = automation_workflows.agency_id
      and m.user_id = auth.uid() and m.status = 'active'
      and m.role in ('agency_admin','marketing_manager'))
);
drop policy if exists "automation managers can update workflows" on public.automation_workflows;
create policy "automation managers can update workflows"
on public.automation_workflows for update to authenticated
using (
  agency_id in (select public.current_agency_ids())
  and exists (select 1 from public.agency_memberships m
    where m.agency_id = automation_workflows.agency_id
      and m.user_id = auth.uid() and m.status = 'active'
      and m.role in ('agency_admin','marketing_manager'))
)
with check (
  agency_id in (select public.current_agency_ids())
  and exists (select 1 from public.agency_memberships m
    where m.agency_id = automation_workflows.agency_id
      and m.user_id = auth.uid() and m.status = 'active'
      and m.role in ('agency_admin','marketing_manager'))
);
