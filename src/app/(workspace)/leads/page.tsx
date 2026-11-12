import { createClient } from "@/lib/supabase/server";
import { requirePermission } from "@/lib/auth";
import { createLead } from "@/app/actions";
import { Plus, Users, Search } from "lucide-react";

export default async function LeadsPage() {
  await requirePermission("leads.read");
  const supabase = await createClient();
  const { data: leads, error } = await supabase.from("leads")
    .select("id,full_name,email,phone,source,status,created_at")
    .order("created_at", { ascending: false }).limit(100);
  if (error) throw new Error("Unable to load leads.");
  return <div className="space-y-6">
    <header className="page-heading"><div><div className="eyebrow">Customer relationship management</div><h1 className="page-title">Leads</h1><p className="page-description">Capture, organize and follow up with prospective customers.</p></div><div className="topbar-pill">{leads?.length??0} records</div></header>
    <form action={createLead} className="card space-y-4">
      <div className="flex items-center gap-3"><div className="stat-icon"><Plus size={17}/></div><div><h2 className="card-title">Add a new lead</h2><p className="card-subtitle">Enter customer details to add them to your pipeline.</p></div></div>
      <div className="form-grid">
        <label><span className="form-label">Full name *</span><input className="field" name="full_name" placeholder="e.g. Priya Kumar" required minLength={2} maxLength={120}/></label>
        <label><span className="form-label">Email address</span><input className="field" name="email" type="email" placeholder="customer@example.com"/></label>
        <label><span className="form-label">Phone number</span><input className="field" name="phone" placeholder="+91 98765 43210"/></label>
        <label><span className="form-label">Lead source</span><select className="field" name="source"><option value="website">Website</option><option value="facebook">Facebook</option><option value="referral">Referral</option><option value="walk_in">Walk-in</option><option value="partner">Partner</option><option value="other">Other</option></select></label>
        <label><span className="form-label">Lead status</span><select className="field" name="status"><option value="new">New</option><option value="contacted">Contacted</option><option value="qualified">Qualified</option><option value="site_visit">Site visit</option><option value="negotiation">Negotiation</option><option value="won">Won</option><option value="lost">Lost</option></select></label>
        <div className="flex items-end"><button className="btn w-full"><Plus size={15}/> Save lead</button></div>
      </div>
    </form>
    <div className="card"><div className="flex items-center justify-between mb-3"><div><h2 className="card-title">All leads</h2><p className="card-subtitle">Your latest customer enquiries</p></div><div className="stat-icon"><Users size={17}/></div></div>
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Customer</th><th>Contact</th><th>Source</th><th>Status</th><th>Created</th></tr></thead><tbody>{(leads??[]).map(lead=><tr key={lead.id}><td>{lead.full_name}</td><td>{lead.email||lead.phone||"—"}</td><td className="capitalize">{lead.source.replaceAll("_"," ")}</td><td><span className={`status-pill ${lead.status==="won"?"green":lead.status==="lost"?"gray":lead.status==="new"?"amber":""}`}>{lead.status.replaceAll("_"," ")}</span></td><td>{new Date(lead.created_at).toLocaleDateString()}</td></tr>)}{(!leads||leads.length===0)&&<tr><td colSpan={5}><div className="empty-state">No leads yet. Add your first customer enquiry above.</div></td></tr>}</tbody></table></div>
    </div>
  </div>;
}
