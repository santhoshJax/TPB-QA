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
### Engagement state — 2026-11-06
**Status:** at risk — 3 test failures investigated: 2 real defects found (customer set criteria, Activity Product batch logic), 1 false alarm. Ready for Build se…

**Done this session**
- Confirmed customer set AS-00000154 criteria is invalid SOQL — blocks all new Retailer account creation
- Confirmed Activity Product batch counts each row not each product — deletes OOS products prematurely on multi-row visits
- Confirmed Sync ID Mapping check is false alarm — rows are short-lived by design

**Open items**
- Decide on 3 missing System Settings records (EnableClickToDial, Promotion_Reco_Pricing_Templates, Account_Operating_Hour_Enabled)
- Decide on Default Location sharing — manual share vs sharing rule
- Decide on metadata refresh — compare package copy with deployed version
- Fix customer set AS-00000154 criteria (now or in Build session)
- Plan Build session: batch logic to count products once per visit, investigate second Distribution row creation
- Confirm Activity Product deletion rule still intended after 3 out-of-stock visits
- Check Penny Perfect Pricing setup and license assignments in org
- Approve D02 cleanup groups before applying record changes to org

**Decisions**
- Mobile app translations marked Not applicable; steps retained for future language support
- DSD and Van Sales package flows can remain inactive — org doesn't use those features
- Wording for D01: TPB does van sales through custom setup, not package Van Sales
- Jira comment SAL-463 not posted; review held pending approval
- 15 inactive package flows are not DSD/Van Sales; belong to other features — no action needed
- Sync ID Mapping check should run soon after sync or be removed — current check timing is invalid

**Blockers**
- Customer set AS-00000154 invalid criteria blocks all new Retailer account creation in org

**Next**
- Provide valid SOQL criteria for customer set AS-00000154 or confirm it should be cleared
- Schedule Build session to fix Activity Product batch logic and investigate multi-row visit creation
- Confirm with Connie that 3-strike out-of-stock deletion rule is still intended
- Resume D02 cleanup approval and System Settings/Location sharing/metadata decisions

**Checked live on 2026-11-06:** the Salesforce org, Google Workspace, the repository
### Last session — 2026-11-06
| | |
|---|---|
| Type | REVIEW |
| Outcome | COMPLETED |
| Branch | `tpb-qa-orchestrate` |
| Name | TPB Daily Sync Issues |
| Session | `d76d032d-dd82-4054-af77-3be397e8db87` |
**In its own words (excerpt):**
I checked the org for all three failed rows on the sheet. Each one traces back to Alice Mctest's testing on 4 Nov. Two are real problems with clear causes. The third isn't a defect: the check itself reads the data wrong. I changed nothing in the org.

## 1. New store "Retail test store cosmo" never reached Salesforce (A9 / S4) — confirmed

**Cause:** a customer set's filter contains plain words instead of a valid query condition.

- **The record:** customer set **AS-00000154** ("Testing Offline App Group"). Christa Wiley created it on 3 Nov at 20:03 UTC. Its criteria field holds just `Test stores`.
- **What breaks:** when a Retailer account is created, the customer set code on the Account trigger builds a query from each set's criteria. With this set it becomes `SELECT Id FROM Account WHERE ( Test stores ) AND Id IN ...`, which fails with "unexpected token: 'Test stores'".
- **Proof:** Alice's app log at 14:58:49 UTC on 4 Nov shows that exact error and stack trace for the cosmo account. The store's Account Manager and Account Extension then failed with it.
  - One second later, the app removed all three from the upload queue, so the store is gone from her device too.
  - The sync r

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
