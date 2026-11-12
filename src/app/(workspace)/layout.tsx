import Link from "next/link";
import { headers } from "next/headers";
import { getAppContext } from "@/lib/auth";
import { signOut } from "@/app/actions";
import { LayoutDashboard, Users, Building2, UserRound, Settings, LogOut, Workflow, CalendarDays, Handshake, Wallet, Boxes, ListChecks, Megaphone, Plug, CreditCard, BarChart3 } from "lucide-react";

const nav = [
  {label:"Overview",href:"/dashboard",Icon:LayoutDashboard},
  {label:"Leads",href:"/leads",Icon:Users},
  {label:"Projects",href:"/projects",Icon:Building2},
  {label:"Inventory",href:"/inventory",Icon:Boxes},
  {label:"Follow-ups",href:"/follow-ups",Icon:ListChecks},
  {label:"Site visits",href:"/site-visits",Icon:CalendarDays},
  {label:"Bookings",href:"/bookings",Icon:CalendarDays},
  {label:"Partners",href:"/partners",Icon:Handshake},
  {label:"Commissions",href:"/commissions",Icon:Wallet},
  {label:"Campaigns",href:"/campaigns",Icon:Megaphone},
  {label:"Automation",href:"/automation",Icon:Workflow},
  {label:"Integrations",href:"/integrations",Icon:Plug},
  {label:"Billing",href:"/billing",Icon:CreditCard},
  {label:"Reports",href:"/reports",Icon:BarChart3},
  {label:"Team",href:"/team",Icon:UserRound},
  {label:"Settings",href:"/settings",Icon:Settings}
];

export default async function WorkspaceLayout({ children }: { children: React.ReactNode }) {
  const ctx = await getAppContext();
  const h = await headers();
  const path = h.get("x-pathname") || "";
  const initials = (ctx.email.split("@")[0] || "EF").slice(0,2).toUpperCase();
  return <div className="workspace-shell">
    <aside className="sidebar">
      <Link href="/dashboard" className="brand">
        <div className="brand-mark">E</div>
        <div><div className="brand-name">ESTATEFLOW</div><div className="brand-sub">Real estate workspace</div></div>
      </Link>
      <div className="agency-switch">
        <div className="agency-label">Workspace</div>
        <div className="agency-name">{ctx.agencyName}</div>
        <div className="agency-role">{ctx.agencyRole.replaceAll("_"," ")}</div>
      </div>
      <div className="nav-label">Workspace menu</div>
      <nav className="nav-list">
        {nav.map(({label,href,Icon}) => <Link key={href} href={href}
          className={`nav-link ${path===href ? "active" : ""}`}>
          <Icon size={17} strokeWidth={1.8}/><span>{label}</span>
        </Link>)}
      </nav>
      {ctx.platformRole === "super_admin" && <><div className="nav-label" style={{marginTop:14}}>Platform</div><nav className="nav-list"><Link href="/super-admin" className="nav-link"><Building2 size={17}/><span>Super Admin</span></Link></nav></>}
      <div className="sidebar-bottom">
        <div className="user-chip"><div className="avatar">{initials}</div><div><div className="user-email">{ctx.email}</div><div className="user-caption">Signed in to EstateFlow</div></div></div>
        <form action={signOut}><button className="signout"><LogOut size={14} style={{display:"inline",marginRight:8,verticalAlign:"middle"}}/>Sign out</button></form>
      </div>
    </aside>
    <div className="main-area">
      <div className="topbar">
        <div className="breadcrumb">Workspace <span style={{color:"#b6bfce"}}>/</span> EstateFlow CRM</div>
        <div className="topbar-right"><span className="topbar-pill">Agency workspace</span><div className="avatar">{initials}</div></div>
      </div>
      <main className="content-wrap">{children}</main>
    </div>
  </div>;
}
