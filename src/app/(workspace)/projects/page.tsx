import { createClient } from "@/lib/supabase/server";
import { requirePermission } from "@/lib/auth";
import { createProject } from "@/app/actions";
import { Building2, Plus, MapPin } from "lucide-react";

export default async function ProjectsPage() {
  await requirePermission("projects.read");
  const supabase = await createClient();
  const { data: projects, error } = await supabase.from("projects")
    .select("id,name,location,status,description,created_at")
    .order("created_at", { ascending: false }).limit(100);
  if (error) throw new Error("Unable to load projects.");
  return <div className="space-y-6">
    <header className="page-heading"><div><div className="eyebrow">Property portfolio</div><h1 className="page-title">Projects</h1><p className="page-description">Manage your agency's real estate developments and properties.</p></div><div className="topbar-pill">{projects?.length??0} projects</div></header>
    <form action={createProject} className="card space-y-4">
      <div className="flex items-center gap-3"><div className="stat-icon"><Plus size={17}/></div><div><h2 className="card-title">Create a project</h2><p className="card-subtitle">Add a property development to your agency portfolio.</p></div></div>
      <div className="form-grid"><label><span className="form-label">Project name *</span><input className="field" name="name" placeholder="e.g. Green Valley Residency" required minLength={2}/></label><label><span className="form-label">Location</span><input className="field" name="location" placeholder="City, State"/></label><label className="form-span"><span className="form-label">Project description</span><textarea className="field" name="description" placeholder="Describe the property, configurations and amenities..." rows={3}/></label><div className="form-span flex justify-end"><button className="btn"><Plus size={15}/> Create project</button></div></div>
    </form>
    <section><div className="flex items-center justify-between mb-3"><div><h2 className="card-title">Your portfolio</h2><p className="card-subtitle">Projects created by your agency</p></div></div><div className="grid md:grid-cols-2 xl:grid-cols-3 gap-4">
      {(projects??[]).map(project=><article className="project-card" key={project.id}><div className="project-cover"><Building2 size={18} style={{marginRight:8}}/> ESTATEFLOW PROJECT</div><div className="flex items-start justify-between mt-4 gap-3"><h3 className="font-bold text-sm text-slate-800">{project.name}</h3><span className="status-pill green">{project.status||"active"}</span></div><p className="text-xs text-slate-500 mt-2 flex items-center gap-1"><MapPin size={13}/>{project.location||"Location not specified"}</p><p className="text-xs text-slate-600 leading-6 mt-4 min-h-12">{project.description||"No project description added yet."}</p><div className="border-t border-slate-100 mt-4 pt-3 text-[10px] text-slate-400">Created {new Date(project.created_at).toLocaleDateString()}</div></article>)}
      {(!projects||projects.length===0)&&<div className="card empty-state">No projects created yet. Add your first property development above.</div>}
    </div></section>
  </div>;
}
