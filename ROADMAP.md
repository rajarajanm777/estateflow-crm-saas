# EstateFlow roadmap delivery map

| Phase | Included in this package | Remaining before production |
|---|---|---|
| 1. Multi-tenant foundation | Auth/profile trigger, agency workspace registration RPC, memberships, role updates, platform admin overview, tenant RLS | Admin bootstrap, email invitations, two-tenant isolation tests, rate limiting and security review |
| 2. Core CRM | Leads, projects, team, follow-ups, inventory, site visits, bookings, partners and commission rule/calculation foundations | Full edit/delete flows, assigned-lead scoping, approval/payment lifecycle, import/export and end-to-end QA |
| 3. Marketing & automation | Campaign records, integration registry, workflow configuration, execution/notification ledgers | Queue worker, event subscriptions, retries, OAuth/webhooks and live WhatsApp/email/SMS/telephony delivery |
| 4. SaaS billing & usage | Plans, subscriptions, invoice/payment/usage ledgers and billing screens | Gateway checkout, signed webhook handling, renewals, tax-compliant invoices, add-ons and enforcement of plan quotas |
| 5. Advanced SaaS | Domain registry, landing-page data model, support ledger, usage summary and reporting screen | DNS/SSL automation, white-label routing, full analytics, monitoring, support tooling and integrations |

This is a staged development baseline, not a statement that every third-party service or production operation is live. Refer to `PHASE_COMPLETION_AND_DEPLOYMENT.md` for required setup and launch gates.
