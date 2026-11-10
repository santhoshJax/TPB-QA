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
### Engagement state — 2026-11-10
**Status:** at risk — Offline app sync issue root cause identified; store-creation fix confirmed in QA; insufficient-access problem still open

**Done this session**
- Confirmed TPB_AccountCustomerSetHandler root cause: invalid criteria in AS-00000154 caused store insert to fail
- Verified fix applied 2026-11-10 17:04 UTC: criteria changed to valid filter, store now syncs
- Identified two systemic weaknesses: single bad rule blocks all new stores; 59 queries per save risks hitting limit

**Open items**
- Confirm SAL-20 'Roadmapping' label default handling (ignore when paired with Operations)
- Confirm SAL-504 'Documentation' label handling (cannot-judge when alone, or map to Operations)
- Decide multi-label ticket behaviour: flag-and-ask per ticket, or apply generic mismatch rule
- Clarify Bryan Rowe's Orchestrate and login entries (3–5 Nov): meeting time or ticket work
- Team to fix 14 mismatched time entries per correction messages (Santhosh 4, Shalem 3, Bryan 3, Karan 4)
- Add Jira label to SAL-472 or confirm Operations assignment; clarify SAL-503 for Karan's 4–5 Nov entries
- Paste or attach Salesforce email to SAL-499; add acceptance criteria and definition of done
- Confirm which components use CGCloud_Services certificate; plan renewal before 2027-03-24

**Decisions**
- SA Approved entries only; per-ticket multi-label override for SAL-458, 459, 484 (OfflineApp)
- Unlabelled tickets treated as Operations and judged
- Entries with no ticket ID classified as Operations (mismatches if workstream mismatch)
- Run instructions default to previous Monday–Sunday week (America/Los_Angeles timezone)
- Orchestrate/login entries flagged as judgement call; count as match when all tickets are Operations

**Blockers**
- SAL-20 and SAL-504 label rules unconfirmed; blocks run instructions finalization
- SAL-472 has no Jira label; cannot classify until labelled
- SAL-499 missing Salesforce email; cannot determine which certificate change or required actions
- Offline app Activity Product discrepancy source unidentified; need app count and sample product details
- Insufficient-access error in sync log unresolved; root cause and impact unknown

**Next**
- Plan fix for TPB_AccountCustomerSetHandler: validate criteria safely, skip bad rules, add validation rule to prevent broken criteria
- Investigate insufficient-access error in sync log to determine scope and required remediation
- Provide offline app Activity Product count for 001Ox00001hz1nXIAQ and 3–5 sample product names or IDs
- Team submits corrected time entries per messages (Bryan Rowe 3 entries, Karan Munjal 2 entries)
- Confirm SAL-20 Roadmapping and SAL-504 Documentation label handling rules before next run

**Checked live on 2026-11-10:** nothing — the status above is as recorded, not re-checked
### Last session — 2026-11-10
| | |
|---|---|
| Type | BUILD |
| Outcome | COMPLETED |
| Branch | `tpb-qa-orchestrate` |
| Name | Offline App Sync Isssue |
| Session | `98f31af7-e5e5-41f5-b614-15f046703691` |
**In its own words (excerpt):**
I pulled the class from QA again and read it. Nothing was changed.

## What it does

When a new store is created, this class works out which **Customer Sets** the store belongs to and adds it to them straight away. Customer Sets are the Consumer Goods Cloud groups of stores that promotions and other features are aimed at. Without this class, a new store would only join its sets later, when the sets are next rebuilt.

The header comment says it was written in September 2023 to "Update Customer Anchor Set in Real Time".

## Step by step

1. **When it runs:** right after Account records are inserted, but only for accounts with the **Retailer** record type. Other account types are skipped. It does nothing when an account is edited.
2. **It loads the Customer Sets:** every Customer Set that has a Sales Org (58 today).
3. **It tests the new store against each set.** Each Customer Set has a rule in `TPB_CustomerSetCriteria__c`, written as a query filter, for example `Name LIKE '%Test%'`. For each set, the class builds a query like this:
   *"Find Accounts matching this set's rule, and only among the stores that were just created."*
   If the new store comes back in the results, it belongs

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
