import { createClient } from "@/lib/supabase/server";
import { getAppContext } from "@/lib/auth";
import { ModuleTable } from "@/components/module-table";
import { FollowUpForm } from "./new-form";

export default async function Page(){
  const c=await getAppContext(); const s=await createClient();
  const [{data:tasks},{data:leads}]=await Promise.all([
    s.from("follow_up_tasks").select("id,title,lead_id,due_at,priority,status,assigned_to").eq("agency_id",c.agencyId).order("due_at",{ascending:true}).limit(100),
    s.from("leads").select("id,full_name").eq("agency_id",c.agencyId).order("full_name").limit(500)
  ]);
  return <><FollowUpForm leads={leads??[]}/><ModuleTable title="Follow-ups" description="Keep sales follow-up tasks, owners, due dates and priorities in one place." rows={tasks} columns={[{key:"title",label:"Task"},{key:"lead_id",label:"Lead ID"},{key:"due_at",label:"Due"},{key:"priority",label:"Priority"},{key:"assigned_to",label:"Assigned to"},{key:"status",label:"Status"}]} emptyNote="No follow-up tasks yet. Create your first task above."/></>;
}
