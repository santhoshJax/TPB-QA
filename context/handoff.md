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
**Status:** waiting — D01 CGC 264 Post-Install Review completed; 4 decision items pending

**Done this session**
- Reviewed post-install configuration in tpbi--qa org
- Marked mobile app translations as Not applicable
- Documented findings in D01 review report

**Open items**
- Decide on 3 missing System Settings records (EnableClickToDial, Promotion_Reco_Pricing_Templates, Account_Operating_Hour_Enabled)
- Decide on Default Location sharing — manual share vs sharing rule
- Decide on metadata refresh — compare package copy with deployed version
- Decide on 15 inactive package flows — activate for features in use

**Decisions**
- Mobile app translations marked Not applicable; steps retained for future language support
- Jira comment SAL-463 not posted; review held in session pending approval

**Blockers**
- None

**Next**
- Review D01 CGC 264 Post-Install Review report
- Decide on each of 4 pending items and communicate choices
- Provide exact changes for confirmation before any org modifications

**Checked live on 2026-11-03:** nothing — the status above is as recorded, not re-checked
### Last session — 2026-11-03
| | |
|---|---|
| Type | REVIEW |
| Outcome | COMPLETED |
| Branch | `tpb-qa-orchestrate` |
| Name | TPB-CGC-Upgrade |
| Session | `08cb0396-aa88-47e6-9a05-7c2cccfc2419` |
**In its own words (excerpt):**
I've recorded both answers. I didn't post to SAL-463 and didn't change anything in the org.

- **Jira comment:** not posted. The review stays in this session until you want it on the ticket.
- **Mobile app translations:** now marked **Not applicable** in the report, since mobile users work in English only. The report still lists the steps in case another language is added later.

That leaves 4 items pending your decision:
1. **3 missing System Settings records:** `EnableClickToDial`, `Promotion_Reco_Pricing_Templates` and `Account_Operating_Hour_Enabled`.
2. **Default Location sharing:** it uses a manual share rather than a sharing rule, so it would be lost if the record owner changes.
3. **Additional metadata:** I haven't compared the package's refreshed copy with what's deployed, so it may need redeploying.
4. **15 inactive package flows:** activate them only for features you use.

The updated **D01 — CGC 264 Post-Install Review** is attached to this session. When you decide on any of these, tell me what to apply and I'll set out the exact changes for you to confirm before anything is touched.

Sources: engagement context (none relied on) · checked live: tpbi--qa org (earlier thi

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->
