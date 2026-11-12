# Security notes and threat model

## Trust boundaries
1. Browser input is untrusted.
2. Supabase Auth establishes identity; the browser does not establish tenant membership.
3. `profiles` and `agency_memberships` are authoritative for platform role and agency role.
4. RLS is the final tenant boundary for table reads/writes.
5. Server actions validate input and check permissions before mutations.

## Required before production
- Replace broad MVP policies for visits/bookings/partners/commissions with granular role permissions.
- Add assigned-record visibility for sales agents and partners (the current MVP allows members of an agency to read all agency leads).
- Add explicit authorization for agency creation and invitation workflows.
- Add platform admin write APIs; do not expose broad direct table writes to super-admin screens.
- Add transactional RPCs for booking + commission calculation and snapshot applied rates.
- Add storage buckets with tenant-specific object paths and RLS policies.
- Add automated integration tests that attempt cross-tenant select, insert, update, delete and export.
- Protect public registration and lead capture with rate limits, CAPTCHA/abuse controls and verification.
- Do not log tokens, passwords, full private message content or payment credentials.
- Use a dedicated server-only secret manager for payment and integration credentials.
- Verify webhook signatures and make webhook handlers idempotent.
- Add data retention, export and deletion workflows.
