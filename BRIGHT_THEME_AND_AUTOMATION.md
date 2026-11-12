# EstateFlow Bright Theme + Automation Centre

This package includes the Automation Centre page, workflow create/status server actions, the automation SQL migration, and a bright white/light-blue visual theme.

## Setup
1. Back up your current project.
2. Extract this ZIP.
3. Keep your existing `.env.local` file; it is not included in this ZIP.
4. In Supabase, run `supabase/migrations/002_automation_workflows.sql` only if you have not already successfully run it. Since you already reported success and verified its three policies, do not run it again.
5. Run `npm install` and `npm run dev`.
6. Open `/automation` after signing in.

## Important limitation
The current automation module saves workflow definitions and allows authorized users to change draft/active/paused status. It does not execute background automations, send emails, send WhatsApp messages, or create real follow-up tasks yet.
