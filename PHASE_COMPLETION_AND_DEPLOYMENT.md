# EstateFlow — consolidated phases 1–5 package

This package extends the prior EstateFlow MVP and keeps the existing `.env.local` setup outside the ZIP.

## What is included

- **Phase 1 foundation:** existing Supabase Auth/profile, agency and membership model; additive profile-on-auth trigger; authenticated self-service agency workspace creation RPC; platform admin overview; agency role update RPC; tenant-scoped RLS.
- **Phase 2 CRM:** existing leads/projects/team plus site visits, bookings, partners, commissions; new inventory-unit and follow-up-task tables and workspace screens.
- **Phase 3 marketing & automation:** existing workflow configuration centre; campaign records and integration registry; automation execution ledger and notification log tables. The execution queue/worker and provider webhooks are not deployed by this ZIP.
- **Phase 4 billing:** existing plans/subscriptions plus invoice, payment-event and usage-event ledgers and billing screen. Checkout, recurring collection, tax invoices and signed provider webhooks require a configured payment provider.
- **Phase 5 advanced:** agency custom-domain registry, landing-page data model, support request ledger, usage summary view and analytics screen. DNS verification, SSL provisioning, white-label routing and full observability require hosting/domain setup.
- **Theme:** red, warm yellow and pale green.

## Important before applying migration 003

1. Back up the Supabase project first.
2. In Supabase SQL Editor, run `supabase/migrations/003_full_platform_foundation.sql` once, after migrations 001 and 002 have already been applied.
3. Do not rerun migrations 001 or 002. Your existing automation workflow table and policies are preserved.
4. Migration 003 is additive; it creates new tables, indexes, functions, triggers, views and policies. Review it in a staging project before production.
5. The new operational screens require migration 003. If it has not been applied, those pages will report missing-table errors.

## Local setup

1. Extract the ZIP.
2. Copy the project folder into your development location.
3. Keep your existing `.env.local` file unchanged. Never commit it or share service-role keys.
4. Run `npm install`.
5. Run `npm run dev` and open `http://localhost:3000`.
6. Run `npm run build` before deployment. Fix any environment or type errors shown by your local build.

## Super Admin bootstrap

For security, this project does not automatically make the first user a platform Super Admin. After verifying the correct account in Supabase Auth, an existing project owner must set that user's `profiles.platform_role` to `super_admin` from the Supabase SQL Editor. Never expose this permission in public signup.

## External services still requiring setup

- WhatsApp Business Cloud API / approved templates and webhook URL
- Email provider (SMTP or transactional email API)
- SMS/telephony provider and sender registration
- Meta/Facebook lead ads OAuth app, permissions and webhook verification
- Payment gateway account, API keys, webhook signing secret and tax configuration
- Public domain, DNS records, SSL and custom-domain routing
- Background job/queue worker for automation execution, retries and failure handling

The UI and database registries are not proof that these services are connected. Do not advertise these as live until end-to-end tests pass.

## Production launch checklist

- Configure production Supabase Auth redirect URLs and SMTP.
- Verify every RLS policy using at least two separate agency accounts.
- Test role restrictions and tenant isolation, including direct API requests.
- Configure rate limits, backups, monitoring, error reporting and retention policies.
- Add provider secrets only to the hosting platform's encrypted environment variables.
- Test payment webhooks, idempotency and refunds in provider sandbox before live mode.
- Test the complete lead-to-site-visit-to-booking-to-commission journey.
- Run `npm run build` and smoke tests in CI before deployment.

This is a substantial implementation foundation, not a claim of completed production certification. External services, security review, full CRUD coverage and end-to-end tests remain launch gates.

## Review update — 12 November 2026

- Supabase migration 003 was applied in the user's project and the 12 additive tables were verified.
- RLS was confirmed enabled on all 12 added tables; tenant read and write policy entries were also confirmed present. This verifies policy installation, not the complete behavior of role/tenant access. Test with separate agency accounts before production.
- The workspace styling has been consolidated around the requested brick-red, warm-yellow and pale-green palette.
- The follow-up form now selects a lead from the current agency's lead list instead of asking staff to paste a lead UUID.
- A local production build was not run during this package review because dependencies were not available in the review environment. Run `npm install`, `npm run typecheck`, and `npm run build` locally before deployment.
