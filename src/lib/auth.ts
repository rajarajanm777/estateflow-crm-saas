import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type AppContext = {
  userId: string;
  email: string;
  platformRole: string;
  agencyId: string;
  agencyRole: string;
  agencyName: string;
};

export async function getAppContext(): Promise<AppContext> {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("platform_role")
    .eq("id", user.id)
    .maybeSingle();

  const { data: membership } = await supabase
    .from("agency_memberships")
    .select("agency_id, role, agencies(name, status)")
    .eq("user_id", user.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (profile?.platform_role === "super_admin") {
    return {
      userId: user.id, email: user.email ?? "", platformRole: "super_admin",
      agencyId: membership?.agency_id ?? "", agencyRole: "super_admin",
      agencyName: "Platform Administration"
    };
  }

  if (!membership) redirect("/no-workspace");
  const agency = membership.agencies as unknown as { name: string; status: string };
  if (agency.status !== "active") redirect("/account-suspended");

  return {
    userId: user.id, email: user.email ?? "",
    platformRole: profile?.platform_role ?? "user",
    agencyId: membership.agency_id, agencyRole: membership.role,
    agencyName: agency.name
  };
}

export async function requirePermission(permission: string) {
  const ctx = await getAppContext();
  if (ctx.platformRole === "super_admin") return ctx;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("has_agency_permission", {
    target_agency: ctx.agencyId, required_permission: permission
  });
  if (error || data !== true) throw new Error("You do not have permission to perform this action.");
  return ctx;
}