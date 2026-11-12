 "use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { requirePermission, getAppContext } from "@/lib/auth";

const leadSchema = z.object({
  full_name: z.string().trim().min(2).max(120),
  email: z.string().trim().email().max(255).or(z.literal("")),
  phone: z.string().trim().max(30).or(z.literal("")),
  source: z.enum(["website","facebook","referral","walk_in","partner","other"]),
  status: z.enum(["new","contacted","qualified","site_visit","negotiation","won","lost"])
});

export async function createLead(formData: FormData) {
  const ctx = await requirePermission("leads.create");
  const parsed = leadSchema.safeParse(Object.fromEntries(formData.entries()));
  if (!parsed.success) throw new Error("Invalid lead details. Please check the form.");
  const supabase = await createClient();
  const { error } = await supabase.from("leads").insert({
    ...parsed.data, agency_id: ctx.agencyId, created_by: ctx.userId,
    email: parsed.data.email || null, phone: parsed.data.phone || null
  });
  if (error) throw new Error("Could not create lead: " + error.message);
  await supabase.from("audit_logs").insert({
    agency_id: ctx.agencyId, actor_id: ctx.userId, action: "lead.created",
    entity_type: "lead", metadata: { source: parsed.data.source }
  });
  revalidatePath("/leads"); revalidatePath("/dashboard");
}

const projectSchema = z.object({
  name: z.string().trim().min(2).max(150),
  location: z.string().trim().max(250).or(z.literal("")),
  description: z.string().trim().max(2000).or(z.literal(""))
});

export async function createProject(formData: FormData) {
  const ctx = await requirePermission("projects.create");
  const parsed = projectSchema.safeParse(Object.fromEntries(formData.entries()));
  if (!parsed.success) throw new Error("Invalid project details.");
  const supabase = await createClient();
  const { error } = await supabase.from("projects").insert({
    ...parsed.data, agency_id: ctx.agencyId, created_by: ctx.userId,
    location: parsed.data.location || null, description: parsed.data.description || null
  });
  if (error) throw new Error("Could not create project: " + error.message);
  await supabase.from("audit_logs").insert({
    agency_id: ctx.agencyId, actor_id: ctx.userId, action: "project.created",
    entity_type: "project"
  });
  revalidatePath("/projects"); revalidatePath("/dashboard");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  revalidatePath("/");
}

const workflowSchema = z.object({
  name: z.string().trim().min(3).max(120),
  trigger_type: z.enum(["lead_created", "lead_status_changed", "site_visit_scheduled"]),
  condition_field: z.enum(["any", "source", "status"]),
  condition_value: z.string().trim().max(80),
  action_type: z.enum(["assign_to_admin", "create_followup_task", "send_email_notice"]),
  action_message: z.string().trim().max(500)
});

async function requireAutomationManager() {
  const ctx = await requirePermission("leads.read");
  if (!["agency_admin", "marketing_manager"].includes(ctx.agencyRole) && ctx.platformRole !== "super_admin") {
    throw new Error("Only an agency admin or marketing manager can manage automations.");
  }
  return ctx;
}

export async function createWorkflow(formData: FormData) {
  const ctx = await requireAutomationManager();
  const parsed = workflowSchema.safeParse(Object.fromEntries(formData.entries()));
  if (!parsed.success) throw new Error("Please check the workflow details and try again.");
  const supabase = await createClient();
  const { error } = await supabase.from("automation_workflows").insert({
    agency_id: ctx.agencyId, created_by: ctx.userId, name: parsed.data.name,
    trigger_type: parsed.data.trigger_type,
    condition_config: { field: parsed.data.condition_field, value: parsed.data.condition_value },
    action_type: parsed.data.action_type, action_config: { message: parsed.data.action_message },
    status: "draft"
  });
  if (error) throw new Error("Could not save workflow: " + error.message);
  await supabase.from("audit_logs").insert({ agency_id: ctx.agencyId, actor_id: ctx.userId, action: "automation.workflow_created", entity_type: "automation_workflow", metadata: { name: parsed.data.name } });
  revalidatePath("/automation");
}

export async function setWorkflowStatus(formData: FormData) {
  const ctx = await requireAutomationManager();
  const id = z.string().uuid().safeParse(formData.get("workflow_id"));
  const status = z.enum(["draft", "active", "paused"]).safeParse(formData.get("status"));
  if (!id.success || !status.success) throw new Error("Invalid workflow update.");
  const supabase = await createClient();
  const { error } = await supabase.from("automation_workflows").update({ status: status.data, updated_at: new Date().toISOString() }).eq("id", id.data).eq("agency_id", ctx.agencyId);
  if (error) throw new Error("Could not update workflow: " + error.message);
  await supabase.from("audit_logs").insert({ agency_id: ctx.agencyId, actor_id: ctx.userId, action: "automation.workflow_status_changed", entity_type: "automation_workflow", entity_id: id.data, metadata: { status: status.data } });
  revalidatePath("/automation");
}

const taskSchema = z.object({title:z.string().trim().min(2).max(160),lead_id:z.string().uuid().or(z.literal("")),due_at:z.string().optional(),priority:z.enum(["low","normal","high"])});
export async function createFollowUp(formData:FormData){const ctx=await requirePermission("leads.read");const p=taskSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please check the follow-up details.");const s=await createClient();const {error}=await s.from("follow_up_tasks").insert({agency_id:ctx.agencyId,title:p.data.title,lead_id:p.data.lead_id||null,due_at:p.data.due_at||null,priority:p.data.priority,created_by:ctx.userId});if(error)throw new Error(error.message);revalidatePath("/follow-ups");}
const unitSchema=z.object({project_id:z.string().uuid(),unit_code:z.string().trim().min(1).max(40),unit_type:z.string().max(80).or(z.literal("")),area_sqft:z.coerce.number().nonnegative().optional(),price:z.coerce.number().nonnegative(),status:z.enum(["available","blocked","reserved","sold"])});
export async function createInventoryUnit(formData:FormData){const ctx=await requirePermission("projects.create");const p=unitSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please check the inventory details.");const s=await createClient();const {error}=await s.from("inventory_units").insert({...p.data,agency_id:ctx.agencyId,unit_type:p.data.unit_type||null});if(error)throw new Error(error.message);revalidatePath("/inventory");}
const campaignSchema=z.object({name:z.string().trim().min(2).max(140),channel:z.enum(["email","whatsapp","sms","social","other"]),budget:z.coerce.number().nonnegative(),content:z.string().max(5000).or(z.literal(""))});
export async function createCampaign(formData:FormData){const ctx=await requirePermission("leads.read");const p=campaignSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please check the campaign details.");const s=await createClient();const {error}=await s.from("marketing_campaigns").insert({...p.data,agency_id:ctx.agencyId,created_by:ctx.userId,content:p.data.content||null});if(error)throw new Error(error.message);revalidatePath("/campaigns");}
export async function registerAgency(formData:FormData){const name=String(formData.get("agency_name")??"");const email=String(formData.get("business_email")??"");const city=String(formData.get("city")??"");const state=String(formData.get("state")??"");const s=await createClient();const {data,error}=await s.rpc("create_agency_workspace",{agency_name:name,business_email:email,agency_city:city,agency_state:state});if(error)throw new Error(error.message);revalidatePath("/");redirect("/dashboard");}

const visitSchema=z.object({lead_id:z.string().uuid(),project_id:z.string().uuid(),scheduled_at:z.string().min(1),notes:z.string().max(1000).or(z.literal(""))});
export async function createSiteVisit(formData:FormData){const ctx=await requirePermission("leads.read");const p=visitSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please select a lead, project and visit time.");const s=await createClient();const {error}=await s.from("site_visits").insert({...p.data,agency_id:ctx.agencyId,created_by:ctx.userId,notes:p.data.notes||null});if(error)throw new Error(error.message);revalidatePath("/site-visits");}
const bookingSchema=z.object({lead_id:z.string().uuid(),project_id:z.string().uuid(),booking_reference:z.string().trim().min(2).max(80),amount:z.coerce.number().nonnegative()});
export async function createBooking(formData:FormData){const ctx=await requirePermission("leads.read");const p=bookingSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please check the booking details.");const s=await createClient();const {error}=await s.from("bookings").insert({...p.data,agency_id:ctx.agencyId,created_by:ctx.userId});if(error)throw new Error(error.message);revalidatePath("/bookings");}
const partnerSchema=z.object({full_name:z.string().trim().min(2).max(120),email:z.string().email().or(z.literal("")),phone:z.string().max(30).or(z.literal("")),partner_type:z.enum(["main","sub"]),parent_partner_id:z.string().uuid().or(z.literal(""))});
export async function createPartner(formData:FormData){const ctx=await requirePermission("leads.read");const p=partnerSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please check the partner details.");const s=await createClient();const {error}=await s.from("channel_partners").insert({...p.data,agency_id:ctx.agencyId,email:p.data.email||null,phone:p.data.phone||null,parent_partner_id:p.data.parent_partner_id||null});if(error)throw new Error(error.message);revalidatePath("/partners");}
export async function calculateCommission(formData:FormData){const ctx=await requirePermission("leads.read");const booking=String(formData.get("booking_id")??"");const partner=String(formData.get("partner_id")??"");if(!z.string().uuid().safeParse(booking).success||!z.string().uuid().safeParse(partner).success)throw new Error("Select a valid booking and partner.");const s=await createClient();const {error}=await s.rpc("create_booking_commission",{target_booking:booking,target_partner:partner});if(error)throw new Error(error.message);revalidatePath("/commissions");}
const ruleSchema=z.object({partner_type:z.enum(["main","sub"]),calculation_type:z.enum(["percentage","fixed"]),rate:z.coerce.number().nonnegative(),project_id:z.string().uuid().or(z.literal(""))});
export async function createCommissionRule(formData:FormData){const ctx=await requirePermission("leads.read");const p=ruleSchema.safeParse(Object.fromEntries(formData.entries()));if(!p.success)throw new Error("Please check the commission rule.");const s=await createClient();const {error}=await s.from("commission_rules").insert({...p.data,agency_id:ctx.agencyId,project_id:p.data.project_id||null});if(error)throw new Error(error.message);revalidatePath("/commissions");}
const memberRoleSchema=z.enum(["agency_admin","sales_manager","sales_agent","marketing_manager","marketing_executive","customer_support","accounts_finance","inventory_manager","main_channel_partner","sub_channel_partner"]);
export async function updateMemberRole(formData:FormData){const ctx=await getAppContext();if(ctx.agencyRole!=="agency_admin")throw new Error("Only the agency admin can update member roles.");const user=String(formData.get("user_id")??"");const role=memberRoleSchema.safeParse(formData.get("role"));if(!z.string().uuid().safeParse(user).success||!role.success)throw new Error("Invalid member role.");const s=await createClient();const {error}=await s.rpc("set_agency_member_role",{target_agency:ctx.agencyId,target_user:user,target_role:role.data});if(error)throw new Error(error.message);revalidatePath("/team");}
