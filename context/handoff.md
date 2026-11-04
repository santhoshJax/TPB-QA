# Handoff — current state

> **Rewritten at the end of every session.** This file is *now*; [`gotchas.md`](gotchas.md) is *forever*.
> If this file and [`../CONTEXT.md`](../CONTEXT.md) disagree, this one is newer.

**Last updated:** 2026-11-03 · **By:** <session or person>

---

## Where things stand

> **Not yet filled in.** — Where is the work right now, in two or three sentences? Someone picking
> this up cold reads this first.

## In progress

| What | State | Where it lives | Blocked on |
|---|---|---|---|
| | | | |

## Next steps

<!-- Ordered. The top item should be the one to do next, not the most interesting one. -->

1.

## Waiting on someone else

| What | Who | Since | Chased? |
|---|---|---|---|
| | | | |

## Things the next session should know

<!-- Anything true right now that is not obvious from the code: a half-finished refactor, a
     deliberately disabled test, a workaround that needs removing, a deploy that is half-applied.
     If you leave something in a strange state, this is where you say so. -->

-

<!-- orchestrate:session-state:start -->
<!-- Written by Orchestrate at the end of each session. Edits inside this block are
     replaced next session; anything OUTSIDE it is yours and is never touched. -->
### Engagement state — 2026-11-04
**Status:** at risk — D02 cleanup report complete; 4 System Settings + Location sharing + metadata decisions still pending; ready for approval before org changes

**Done this session**
- Completed D02 DSD/Van Sales usage and cleanup analysis with full evidence and cleanup order
- Confirmed 15 inactive flows are not DSD/Van Sales; belong to other package features
- Clarified package 264 has no DSD/Route Sales data changes after 258 — no 264-specific cleanup needed
- Identified 4 custom permission sets (1 assigned to admin, 3 unassigned) for removal consideration

**Open items**
- Decide on 3 missing System Settings records (EnableClickToDial, Promotion_Reco_Pricing_Templates, Account_Operating_Hour_Enabled)
- Decide on Default Location sharing — manual share vs sharing rule
- Decide on metadata refresh — compare package copy with deployed version
- Check Penny Perfect Pricing in org (license assignments, setup)
- Approve D02 cleanup groups before applying exact record changes to org
- Plan QA test schedule: TPB inventory batches, mobile cash-sale flow, Penny Perfect Pricing on 264
- Confirm cleanup scope for production org (same usage checks required)

**Decisions**
- Mobile app translations marked Not applicable; steps retained for future language support
- DSD and Van Sales package flows can remain inactive — org doesn't use those features
- Wording for D01: TPB does van sales through custom setup, not package Van Sales
- Jira comment SAL-463 not posted; review held pending approval
- 15 inactive package flows are not DSD/Van Sales; belong to other features — no action needed on these

**Blockers**
- None

**Next**
- Review and approve D02 cleanup groups (personas, templates, tours, routes, permission sets)
- Resolve 4 pending System Settings, Location sharing, metadata refresh decisions
- Provide exact record changes for each approved cleanup group; set out for confirmation before org modifications
- Check Penny Perfect Pricing setup and license assignments in org (read-only)
- Confirm QA test scope includes Penny Perfect Pricing validation on 264

**Checked live on 2026-11-04:** nothing — the status above is as recorded, not re-checked
### Last session — 2026-11-04
| | |
|---|---|
| Type | REVIEW |
| Outcome | COMPLETED |
| Branch | `tpb-qa-orchestrate` |
| Name | TPB-CGC-Upgrade |
| Session | `08cb0396-aa88-47e6-9a05-7c2cccfc2419` |
**In its own words (excerpt):**
TPB does not use the package's Direct Store Delivery (DSD) or Van Sales features. It does do van sales, but through its own setup: TPB inventory templates, TPB Apex and cash-sale transactions, all running on the standard mobile setup. That means your cleanup question applies. The 264 update question doesn't: the package ships no DSD or Route Sales data changes after release 258, so 264 has nothing DSD-specific to apply. I changed nothing in the org.

**Why I'm confident**
- **The meeting:** Bryan said reps sell from their vans only to "certain stores only, certain chains". Most orders go through the wholesaler, and TPB runs no delivery runs of its own.
- **Mobile app:** all 539 installs use the standard mobile persona (the app setup a user group syncs with, called `TquilaONE`). None uses the DSD, Hybrid or Route Sales persona.
- **Orders and tours:** all 310,631 orders use the Standard template. There are no vehicles or routes, and all 49 tours are "Standard Tour" and still at "Initial" status.

**Must stay, because TPB's van setup depends on it**
- **Package objects:** Tour, Warehouse, Inventory, Inventory Transaction, Order Payment and Vehicle. About 20 TPB Apex classes use them,

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
