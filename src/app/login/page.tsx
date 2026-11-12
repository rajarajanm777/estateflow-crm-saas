import LoginForm from "./form";

export default function LoginPage() {
  return <main className="min-h-screen grid place-items-center p-5">
    <section className="card w-full max-w-md">
      <div className="mb-7">
        <div className="text-sm font-bold text-blue-700">ESTATEFLOW</div>
        <h1 className="text-2xl font-bold mt-2">Welcome back</h1>
        <p className="muted mt-1 text-sm">Sign in to your agency workspace.</p>
      </div>
      <LoginForm />
    </section>
  </main>;
}