import Link from "next/link";
import { getAppContext } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { Users, Building2, UserRound, CalendarCheck, ArrowUpRight, Plus, Sparkles } from "lucide-react";

export default async function DashboardPage() {
  const ctx = await getAppContext();
  const supabase = await createClient();
  const [leads, projects, team, visits, recentLeads, recentProjects] = await Promise.all([
    supabase.from("leads").select("id", { count: "exact", head: true }),
    supabase.from("projects").select("id", { count: "exact", head: true }),
    supabase.from("agency_memberships").select("id", { count: "exact", head: true }).eq("status","active"),
    supabase.from("site_visits").select("id", { count: "exact", head: true }),
    supabase.from("leads").select("id,full_name,status,created_at").order("created_at",{ascending:false}).limit(4),
    supabase.from("projects").select("id,name,location,created_at").order("created_at",{ascending:false}).limit(3)
  ]);
  const stats = [
    {label:"Total leads",value:leads.count??0,Icon:Users,foot:"Customer enquiries"},
    {label:"Active projects",value:projects.count??0,Icon:Building2,foot:"Property developments"},
    {label:"Team members",value:team.count??0,Icon:UserRound,foot:"Active workspace users"},
    {label:"Site visits",value:visits.count??0,Icon:CalendarCheck,foot:"Scheduled visits"}
  ];
  return <div>
    <header className="page-heading"><div><div className="eyebrow">Workspace overview</div><h1 className="page-title">Good day, welcome back</h1><p className="page-description">Here's what's happening at {ctx.agencyName}.</p></div><Link className="btn" href="/leads"><Plus size={15}/> Add a lead</Link></header>
    <section className="stat-grid">{stats.map(({label,value,Icon,foot})=><div className="stat-card" key={label}><div className="stat-top"><div className="stat-label">{label}</div><div className="stat-icon"><Icon size={17}/></div></div><div className="stat-value">{value}</div><div className="stat-foot">{foot}</div></div>)}</section>
    <section className="dashboard-grid">
      <div className="welcome-card"><div className="eyebrow" style={{color:"#c8d8ff"}}>ESTATEFLOW WORKSPACE</div><div className="welcome-title">Build stronger customer relationships.</div><p className="welcome-copy">Keep your property projects, enquiries and team activity organized in one place. Start by adding a project or capturing a new lead.</p><Link className="quick-link" href="/projects"><Plus size={14}/> Create project</Link><Link className="quick-link" href="/leads"><Users size={14}/> Manage leads</Link></div>
      <div className="card"><div className="card-title">Quick overview</div><div className="card-subtitle">Your workspace at a glance</div><div className="activity-item"><div className="activity-dot"/><div className="activity-text"><b>{leads.count??0} leads</b><br/>Customer enquiries captured</div></div><div className="activity-item"><div className="activity-dot" style={{background:"#38a77a"}}/><div className="activity-text"><b>{projects.count??0} projects</b><br/>Real estate projects created</div></div><div className="activity-item"><div className="activity-dot" style={{background:"#e3a43b"}}/><div className="activity-text"><b>{team.count??0} team members</b><br/>Active agency memberships</div></div></div>
    </section>
    <section className="dashboard-grid">
      <div className="card"><div className="flex items-center justify-between mb-3"><div><div className="card-title">Recent leads</div><div className="card-subtitle">Latest customer enquiries</div></div><Link href="/leads" className="text-xs font-bold text-blue-600">View all <ArrowUpRight size={13} style={{display:"inline"}}/></Link></div>
        {(recentLeads.data??[]).length ? (recentLeads.data??[]).map(l=><div className="activity-item" key={l.id}><div className="avatar">{l.full_name.slice(0,1).toUpperCase()}</div><div className="activity-text" style={{flex:1}}><b>{l.full_name}</b><br/><span className="capitalize">{l.status.replaceAll("_"," ")}</span></div><span className="text-xs text-slate-400">{new Date(l.created_at).toLocaleDateString()}</span></div>):<div className="empty-state">No leads yet. Your new enquiries will appear here.</div>}
      </div>
      <div className="card"><div className="flex items-center justify-between mb-3"><div><div className="card-title">Your projects</div><div className="card-subtitle">Recently added properties</div></div><Link href="/projects" className="text-xs font-bold text-blue-600">View all</Link></div>
        {(recentProjects.data??[]).length ? (recentProjects.data??[]).map(p=><div className="activity-item" key={p.id}><div className="stat-icon"><Building2 size={16}/></div><div className="activity-text"><b>{p.name}</b><br/>{p.location||"Location not specified"}</div></div>):<div className="empty-state">No projects yet. Add your first development.</div>}
      </div>
    </section>
  </div>;
}
