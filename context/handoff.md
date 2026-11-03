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
**Status:** at risk — D01 review complete; 4 decisions pending + Penny Perfect Pricing discovery; ready to add DSD/Van Sales section to D01

**Done this session**
- Validated org van-sales findings against meeting transcript (Bryan Rowe, 1 Jun 2026)
- Confirmed TPB does van sales via custom setup, not package Van Sales feature
- Identified Penny Perfect Pricing as business-critical but unchecked in org

**Open items**
- Decide on 3 missing System Settings records (EnableClickToDial, Promotion_Reco_Pricing_Templates, Account_Operating_Hour_Enabled)
- Decide on Default Location sharing — manual share vs sharing rule
- Decide on metadata refresh — compare package copy with deployed version
- Decide on 15 inactive package flows — activate only those for features in use
- Check Penny Perfect Pricing in org (license assignments, setup)
- Add DSD/Van Sales usage section to D01 report citing meeting evidence
- Plan QA test schedule: TPB inventory batches, mobile cash-sale flow, Penny Perfect Pricing on 264

**Decisions**
- Mobile app translations marked Not applicable; steps retained for future language support
- DSD and Van Sales package flows can remain inactive — org doesn't use those features
- Wording for D01: TPB does van sales through custom setup, not package Van Sales
- Jira comment SAL-463 not posted; review held pending approval

**Blockers**
- None

**Next**
- Check Penny Perfect Pricing setup and license assignments in org (read-only)
- Resolve 4 pending System Settings, Location sharing, metadata refresh, flow activation decisions
- Draft DSD/Van Sales usage section for D01 with meeting citation
- Confirm QA test scope includes Penny Perfect Pricing validation
- Provide exact changes for each decision; set out for confirmation before org modifications

**Checked live on 2026-11-03:** meeting transcripts
### Last session — 2026-11-03
| | |
|---|---|
| Type | REVIEW |
| Outcome | COMPLETED |
| Branch | `tpb-qa-orchestrate` |
| Name | TPB-CGC-Upgrade |
| Session | `08cb0396-aa88-47e6-9a05-7c2cccfc2419` |
**In its own words (excerpt):**
The meeting supports what I found in the org, with one change to how it should be worded. TPB does van sales as a business. It runs them through its own TPB van-inventory and cash-sale setup, not the package's standard Van Sales feature. Neither the meeting nor the org shows TPB running standard Direct Store Delivery with its own trucks.

**What the meeting says** (Internal | TPB Standup, 1 Jun 2026, Bryan Rowe answering Santhosh):
- **Van sales: yes, but not often.** Only for "certain stores only, certain chains". Reps carry real stock in their vans and sell it to stores directly.
- **Usual path: wholesaler orders.** "Mostly they set up orders from the wholesaler where they act as the middleman and then the store gets a direct delivery from the wholesaler."
- **Direct-to-store selling falls under van sales.** Bryan put it this way: "they do sell out of their vans to the store, but that'd be under the van delivery." There's no separate delivery run of TPB's own.

**How that matches the org**

| Meeting | Org (checked earlier this session) | Match |
|---|---|---|
| Reps sell from van stock, now and then | 65,499 user inventory records on the "TPB Control Template". 1.67M inventory m

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
