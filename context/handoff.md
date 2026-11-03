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
### Engagement state — 2026-11-03
**Status:** at risk — D01 review complete; DSD/Van Sales unused but 4 decisions pending before upgrade can proceed

**Done this session**
- Confirmed org uses TPB custom van inventory (65K records, 1.67M transactions), not standard DSD/Van Sales
- Identified 15 inactive package flows: DSD and Van Sales ones can stay off; order flows unused
- Mapped TPB Apex dependencies: van-inventory batch, user-balance batch, mobile cash-sale flow need QA testing

**Open items**
- Decide on 3 missing System Settings records (EnableClickToDial, Promotion_Reco_Pricing_Templates, Account_Operating_Hour_Enabled)
- Decide on Default Location sharing — manual share vs sharing rule
- Decide on metadata refresh — compare package copy with deployed version
- Decide on 15 inactive package flows — activate only those for features in use
- Add DSD/Van Sales usage findings to D01 report if going to delivery lead
- Plan QA test runs: TPB inventory batches and mobile cash-sale flow on 264

**Decisions**
- Mobile app translations marked Not applicable; steps retained for future language support
- DSD and Van Sales package flows can remain inactive — org doesn't use those features
- Jira comment SAL-463 not posted; review held pending approval

**Blockers**
- None

**Next**
- Decide on 4 pending items (System Settings, Location sharing, metadata refresh, flow activation)
- Confirm whether to add DSD/Van Sales usage section to D01 report
- Provide exact changes for each decision; will set out changes for confirmation before org modifications
- Plan QA test schedule for TPB inventory and mobile flows on 264

**Checked live on 2026-11-03:** the Salesforce org
### Last session — 2026-11-03
| | |
|---|---|
| Type | REVIEW |
| Outcome | COMPLETED |
| Branch | `tpb-qa-orchestrate` |
| Name | TPB-CGC-Upgrade |
| Session | `08cb0396-aa88-47e6-9a05-7c2cccfc2419` |
**In its own words (excerpt):**
The org doesn't use standard Direct Store Delivery (DSD) or Van Sales. It does run its own TPB version of van stock: sales reps carry inventory and record cash sales against it. The package's DSD inventory engine underneath is in heavy daily use. I made no changes to the org.

**Not used**
- **Van Sales and Delivery orders:** the org has 9 Van Sales and 6 Delivery/Return order templates, and most are active. But all 310,629 orders (June 2023 to 30 Oct 2026) use the **Standard** template. No order uses a Van Sales or Delivery template.
- **Vehicles and routes:** there are 0 Vehicle, 0 Vehicle Warehouse and 0 Route records.
- **Driver access:** no active user has the CGC Retail Tour Driver permission set.
- **Tours:** 49 exist, all on the "Standard Tour" template and all still in "Initial" status. Each one is named for a US state ("Tour NY", "Tour AZ"…) and paired with a state warehouse. None has a driver or truck, and none has been started. They act as state groupings rather than real delivery runs.

**Used: TPB's version of van inventory**
- **User inventory:** 65,499 inventory records across 377 users. Almost all are on the custom "TPB Control Template", which holds stock per user

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
