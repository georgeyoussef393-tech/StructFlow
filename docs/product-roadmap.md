# StructFlow: 100-step enterprise product roadmap

This roadmap is ordered by dependency and risk. A feature is not complete just
because its interface exists: server-side authorization, persistence, tests,
operations, and documentation are part of completion. StructFlow is not ready
for customer production data until the security and release gates below pass.

## Foundation and security

1. Run schema migrations against PostgreSQL in CI and verify tenant isolation.
2. Exercise runtime database grants with a non-owner, non-superuser role.
3. Test fail-closed row-level security with missing tenant context.
4. Test row-level security for suspended memberships and organizations.
5. Add migration version tracking, checksums, and safe rollback policy.
6. Add PostgreSQL backup and restore drills with documented recovery targets.
7. Add secret-manager integration for database and signing secrets.
8. Add production health, readiness, and dependency-health endpoints.
9. Add structured request IDs and redacted security event logging.
10. Add dependency, license, secret, and static security scanning in CI.

## Identity and organization administration

11. Replace local demo authentication with API-backed sign-in.
12. Store access credentials only in platform secure storage.
13. Implement invitation creation, delivery, expiry, and one-time acceptance.
14. Implement verified email enrollment and address-change confirmation.
15. Implement secure password reset with one-time expiring tokens.
16. Implement session listing, device metadata, and per-session revocation.
17. Add multi-factor authentication with recovery codes.
18. Add enterprise SSO using OIDC and SAML with tenant-level configuration.
19. Add SCIM user provisioning and deprovisioning.
20. Add organization profile, lifecycle, suspend, and close workflows.

## Authorization and audit

21. Define a server-owned permission matrix for every role and resource.
22. Enforce organization and project permissions on every API operation.
23. Add delegated project and discipline-level permission administration.
24. Add approval workflows for privileged role changes.
25. Add immutable audit trails for identity and organization administration.
26. Add audit event export with filters and integrity verification.
27. Add access reviews and periodic inactive-account recertification.
28. Add configurable session lifetime and organization security policies.
29. Add API rate limiting shared across all service instances.
30. Add abuse detection, lockout safeguards, and alerting for authentication.

## Projects and portfolio

31. Replace local project storage with tenant-scoped API persistence.
32. Add project CRUD with optimistic concurrency and validation.
33. Add project membership and responsibility assignments.
34. Add WBS, phases, milestones, and baseline management.
35. Add project portfolio views with configurable KPIs.
36. Add budgets, cost codes, commitments, and actual cost tracking.
37. Add schedule dependencies, critical path, and baseline comparisons.
38. Add change orders and variation approval workflows.
39. Add risk, issue, and decision registers with ownership and due dates.
40. Add project closeout, handover, and archival controls.

## Tasks and field execution

41. Replace local task storage with tenant-scoped API persistence.
42. Add task assignment, watchers, comments, and activity history.
43. Add task dependencies, recurring tasks, and escalation rules.
44. Add configurable workflows and approval states.
45. Add daily site diaries, weather, labor, equipment, and work quantities.
46. Add inspections, checklists, non-conformance, and corrective actions.
47. Add permit-to-work and safety observation workflows.
48. Add offline field capture with conflict-safe synchronization.
49. Add geotagged and timestamped field evidence with consent controls.
50. Add field-facing performance for low-bandwidth devices and networks.

## Documents and collaboration

51. Replace local document storage with secure object storage and metadata API.
52. Add malware scanning, file-type validation, and size limits on uploads.
53. Add versioned document revisions and immutable revision history.
54. Add transmittals, RFIs, submittals, and review/approval routing.
55. Add granular document access controls and expiring external links.
56. Add watermarking, download audit, and classification labels.
57. Add retention schedules, legal holds, and secure deletion workflows.
58. Add full-text metadata search with tenant isolation.
59. Add in-app notifications and configurable email delivery.
60. Add collaboration comments, mentions, and notification preferences.

## Workforce and time

61. Replace local attendance storage with API persistence.
62. Add shift, overtime, break, and holiday policy configuration.
63. Add supervisor approval and correction history for timesheets.
64. Add privacy-aware geofence attendance with configurable retention.
65. Add labor allocation by project, cost code, and activity.
66. Add workforce skills, certifications, expiry alerts, and training records.
67. Add contractor onboarding and document compliance checks.
68. Add payroll/export integrations with auditable mapping and reconciliation.
69. Add workforce capacity planning and resource conflict detection.
70. Add attendance device and identity-provider integration points.

## Commercial, procurement, and finance

71. Add supplier, subcontractor, and consultant registers.
72. Add purchase requisition, quotation, and purchase order workflows.
73. Add subcontract and payment application tracking.
74. Add budget forecast, committed cost, and earned value metrics.
75. Add multi-currency, tax, and locale-aware monetary precision.
76. Add invoice capture, matching, approval, and exception handling.
77. Add commercial correspondence and claim registers.
78. Add cost-to-complete forecasts with transparent assumptions.
79. Add ERP integration APIs, idempotency, and reconciliation reports.
80. Add financial access controls and segregation-of-duties checks.

## Enterprise operations and integrations

81. Establish documented API versioning and backwards-compatibility policy.
82. Generate and publish OpenAPI specifications for supported endpoints.
83. Add idempotency keys for retriable create and payment-related operations.
84. Add background jobs with retries, deduplication, and dead-letter handling.
85. Add tenant-aware observability, dashboards, alerts, and SLOs.
86. Add horizontal scaling and graceful shutdown/load-shedding behavior.
87. Add disaster recovery, regional recovery, and tenant export procedures.
88. Add configurable data residency and tenant-specific deployment options.
89. Add webhook registration, signatures, retries, and delivery history.
90. Add supported integrations for common construction and identity platforms.

## Quality, accessibility, and commercial readiness

91. Add automated API contract and multi-tenant integration tests.
92. Add end-to-end critical-path tests for web and mobile clients.
93. Add performance and load testing with documented enterprise targets.
94. Add WCAG accessibility checks, keyboard navigation, and screen-reader QA.
95. Complete Arabic/English localization, RTL review, and locale-aware formats.
96. Add responsive design and supported browser/device compatibility tests.
97. Add customer onboarding, tenant provisioning, and guided configuration.
98. Add in-product help, support diagnostics, and privacy-safe feedback tools.
99. Publish security, privacy, uptime, support, and data-processing policies.
100. Establish release gates, customer acceptance pilots, and a regular roadmap
     review based on measured usage and customer feedback.

## Progress

Implemented in the current foundation: initial tenant-scoped API, PostgreSQL
RLS policies on project and audit data, documented restricted runtime grants,
release-build protection for the local-auth demo, and CI analysis/unit tests.
CI is now configured to execute the initial migration and PostgreSQL RLS
integration checks; those checks still need a successful CI run. Global
identity, organization, membership, and session tables do not yet have RLS.
API-backed sign-in, secure token storage, server-side session restore/revocation,
and the demo-workspace gate are implemented for configured development clients;
the Flutter production release remains blocked pending migration of business
data modules. Company-scoped project listing and project creation use the API,
including client, type, budget/currency, and schedule metadata. Project details
are fetched with server-side tenant and membership checks. Owner/admin project
metadata updates use version-based conflict detection and restricted update
grants; project member administration remains unavailable in API mode.
Roadmap items 11, 31, and 32 are therefore in progress, not complete.
The remaining items are not represented as complete merely because they are
listed here.
