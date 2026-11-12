export default function NoWorkspace() {
  return <main className="min-h-screen grid place-items-center p-6"><div className="card max-w-lg">
    <h1 className="text-2xl font-bold">No agency workspace</h1>
    <p className="muted mt-2">Your account is authenticated but is not linked to an active agency. Create your agency workspace to get started, or ask your platform administrator for an invitation.</p><a className="btn mt-5" href="/register-agency">Create agency workspace</a>
  </div></main>;
}