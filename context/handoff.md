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
**Status:** blocked — I checked this without changing anything.

**Done this session**
- I checked this without changing anything. There are two separate problems in that sync log. The store-creation one has since been fixed in QA. The "insufficient access" one is still open. ## 1. "Qwerty" store insert failed (`unexpected tok…

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
- Offline app Activity Product discrepancy source unidentified; need app count and sample product details to proceed

**Next**
- Provide offline app Activity Product count for 001Ox00001hz1nXIAQ and 3–5 sample product names or IDs
- Team submits corrected time entries per messages (Bryan Rowe 3 entries, Karan Munjal 2 entries)
- Add Jira label to SAL-472; clarify whether Karan's 4–5 Nov entries belong to SAL-503 or Operations
- Confirm SAL-20 Roadmapping and SAL-504 Documentation label handling rules before next run
- Attach Salesforce email to SAL-499 and add acceptance criteria; identify certificate dependencies

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
I checked this without changing anything. There are two separate problems in that sync log. The store-creation one has since been fixed in QA. The "insufficient access" one is still open.

## 1. "Qwerty" store insert failed (`unexpected token: 'Test stores'`) — fixed since

**Cause:** When a Retailer account is inserted, `TPB_AccountCustomerSetHandler` goes through every Customer Set that has a Sales Org. It pastes each set's `TPB_CustomerSetCriteria__c` text straight into a query (`SELECT Id FROM Account WHERE ( <criteria> ) AND Id IN :setAccountId`, line 61). Customer Set **AS-00000154** had plain text ("Test stores") in that field instead of a valid filter. The query failed and rolled back the whole Account insert.

The three other errors (`cgcloud__Account_Manager__c`, `cgcloud__Account_Extension__c`, `Visit`) are knock-on failures. They were children of the failed local Account, so they failed with it.

**Current state:**
- At 17:04 UTC today, Santhosh Kumar changed AS-00000154's criteria to `Name LIKE '%Test%'`, which is a valid filter.
- One minute later (17:05 UTC), "Qwerty" synced: it now exists as account `001Ox00001jVJKBIA4`, created by Shalem's test user, with its Visit

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
