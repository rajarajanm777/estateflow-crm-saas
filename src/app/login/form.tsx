 "use client";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

export default function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault(); setBusy(true); setError("");
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) { setError(error.message); setBusy(false); return; }
    router.replace("/dashboard"); router.refresh();
  }

  return <form onSubmit={submit} className="space-y-4">
    <label className="block text-sm font-medium">Email
      <input className="field mt-1" type="email" required value={email}
        onChange={e => setEmail(e.target.value)} autoComplete="email" />
    </label>
    <label className="block text-sm font-medium">Password
      <input className="field mt-1" type="password" required value={password}
        onChange={e => setPassword(e.target.value)} autoComplete="current-password" />
    </label>
    {error && <p className="text-sm text-red-600" role="alert">{error}</p>}
    <button className="btn w-full" disabled={busy}>{busy ? "Signing in..." : "Sign in"}</button>
  </form>;
}