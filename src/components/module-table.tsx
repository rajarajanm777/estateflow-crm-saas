type Column = { key: string; label: string };
export function ModuleTable({title,description,rows,columns,emptyNote,actionHref,actionLabel}: {
 title:string; description:string; rows:Record<string,unknown>[]|null; columns:Column[]; emptyNote:string; actionHref?:string; actionLabel?:string;
}) {
 return <div>
  <div className="page-heading"><div><div className="eyebrow">EstateFlow workspace</div><h1 className="page-title">{title}</h1><p className="page-description">{description}</p></div>{actionHref&&<a className="btn" href={actionHref}>{actionLabel??"Open module"}</a>}</div>
  <section className="card"><div className="flex items-center justify-between gap-3 mb-4"><div><div className="card-title">{title} records</div><div className="card-subtitle">Live records for the selected agency</div></div><span className="status-pill green">{rows?.length??0} records</span></div>
   {rows&&rows.length>0?<div className="table-wrap"><table className="data-table"><thead><tr>{columns.map(c=><th key={c.key}>{c.label}</th>)}</tr></thead><tbody>{rows.map((r,i)=><tr key={String(r.id??i)}>{columns.map(c=><td key={c.key}>{format(r[c.key])}</td>)}</tr>)}</tbody></table></div>:<div className="empty-state">{emptyNote}</div>}
  </section>
 </div>
}
function format(value:unknown):string { if(value===null||value===undefined||value==="") return "—"; if(typeof value==="object") return JSON.stringify(value); if(typeof value==="string"&&value.includes("T")) return new Date(value).toLocaleString(); return String(value); }
