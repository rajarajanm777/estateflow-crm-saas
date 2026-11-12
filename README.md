# EstateFlow — Real Estate CRM SaaS

EstateFlow is a multi-tenant real-estate CRM application built with Next.js 15, React 19, TypeScript and Supabase/PostgreSQL. This consolidated package extends the earlier MVP with workspace modules and additive database foundations for all five roadmap phases.

## Included application areas

- **Platform & tenancy:** Supabase authentication, profiles, agency memberships, tenant-scoped RLS, agency onboarding RPC, Super Admin overview, plan/subscription foundations and member role management.
- **Core CRM:** dashboard, leads, projects, team, inventory units, follow-ups, site visits, bookings, channel partners and commission rules/calculation.
- **Marketing & automation:** campaign records, integration registry, workflow configuration, execution ledger and notification log foundations.
- **SaaS billing:** plans, subscriptions, invoice ledger, payment-event ledger and usage-event tracking foundations.
- **Advanced capabilities:** agency domain registry, landing-page data model, support request ledger, usage summary view and agency reports.
- **Visual theme:** red, warm yellow and pale green.

## Database migration order

For a new Supabase project, run in order:

1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_automation_workflows.sql`
3. `supabase/migrations/003_full_platform_foundation.sql`

For the already configured EstateFlow project, migrations 001 and 002 have already been applied. **Do not rerun them.** Back up the database, then run migration 003 once in Supabase SQL Editor. Read `docs/PHASE_COMPLETION_AND_DEPLOYMENT.md` before applying it.

## Local setup

- Node.js 20+
- npm
- Supabase project

1. Extract this ZIP.
2. Preserve your existing `.env.local` file. Do not upload it or commit it.
3. Install dependencies: `npm install`
4. Start locally: `npm run dev`
5. Open `http://localhost:3000`
6. Before deployment, run `npm run build` and resolve all errors.

Required environment variables are shown in `.env.example`:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Never put a Supabase service-role key in a `NEXT_PUBLIC_` variable or browser bundle.

## Super Admin bootstrap

Create/verify the platform owner's Auth user, then set `profiles.platform_role = 'super_admin'` for that exact user UUID from Supabase SQL Editor. Never let public signup choose its platform role. The Super Admin page is `/super-admin`.

## Feature boundaries — read before launch

The screens and database tables are not equivalent to live third-party integrations. The following still need provider setup and end-to-end implementation/testing:

- Background worker/queue to execute workflows, retries and failure handling.
- WhatsApp Business, email, SMS and telephony provider connections.
- Meta/Facebook lead-ad OAuth and verified webhooks.
- Payment gateway checkout, signed webhooks, recurring billing, refunds and tax invoice handling.
- Domain/DNS/SSL verification and custom-domain routing.
- Complete invite-email workflow, CSV import/export, advanced reporting, audit coverage and production monitoring.

Do not advertise any of these as operational until real provider accounts are connected and end-to-end tests pass. See `docs/PHASE_COMPLETION_AND_DEPLOYMENT.md` for the launch checklist.

## Security baseline

- Agency-owned rows are scoped by `agency_id` and Row Level Security.
- Server actions validate input and check membership/permission before writes.
- Provider secrets belong in encrypted server-side environment variables or a secrets manager, never in the browser or integration JSON config.
- Test tenant isolation with at least two separate agencies before production.

This is a substantial development foundation across phases 1–5, not a certified production release. A successful local production build, provider setup, security review, and end-to-end acceptance testing are required before deployment.

## Latest review update

The follow-up task form now provides a dropdown of leads belonging to the current agency, and the stylesheet applies the requested red/yellow/pale-green theme consistently across the workspace. The Supabase 003 migration has been applied and its 12 new tables, RLS flags, and policy entries were verified in the configured project. This is not a substitute for two-tenant/role behavior testing. The package still requires dependency installation and a successful local typecheck/production build before deployment.
