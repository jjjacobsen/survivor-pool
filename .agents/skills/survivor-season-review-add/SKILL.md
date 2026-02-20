---
name: survivor-season-review-add
description: Review, fix, backfill, or create complete static Survivor season data in db/seasons/season*.js for already-finished seasons. Use when asked to validate an entire season, finish partial season data, or add a missing season file while preserving existing schema/style, including final_week.
---

# Survivor Season Review And Add

Assume the target season has already completed airing.

## Workflow

1. Read `docs/DB_schema.md`, `db/init.js`, and the target `db/seasons/season*.js` file if it exists.
2. Collect full-season sources from:
   - https://survivor.fandom.com/
   - https://www.truedorktimes.com/
3. When fetching source pages, use `https://markdown.new/<url>`.
4. Decide path:
   - File exists and complete: audit all season data and correct errors.
   - File exists and partial: add missing data and correct errors in existing data.
   - File missing: create `db/seasons/seasonNN.js` and populate full season data.
5. Keep file shape consistent with existing season files:
   - Keep the same IIFE structure and top-level constants.
   - Use `idOf("Name")` for contestant references.
   - Preserve naming patterns for arrays and fields.
6. Enforce contestant schema exactly:
   - `id`, `name`, `age`, `occupation`, `hometown`
   - Do not add or remove contestant fields.
7. Ensure `eliminations` is complete and accurate:
   - Include one entry per elimination event (including same-week double boots when applicable).
   - Use correct week numbers and contestant ids.
8. Ensure `final_week` is present and accurate:
   - `final_week` is the final playable pick week for pool completion.
   - If the true finale pick week is unknown, keep `final_week` as `null`.
   - Once known, set it to the same week as the latest elimination entry.
9. Ensure `tribeTimeline` is complete and accurate:
   - Include initial tribes and later tribe-state changes (`swap`, `merge`, etc.).
   - Keep member lists aligned with elimination order and tribe events.
10. Ensure `advantages` is complete and accurate:
    - Keep `acquisition_notes` limited to how the advantage was obtained; never mention play/transfer/vote outcomes there.
    - Set `end_week` and `end_notes` when an advantage leaves the game (played, expired, transferred, voted out with it, or any other exit).
    - Keep `end_notes` as `null` when `end_week` is `null`.
    - When an advantage transfers in a later week, end the original entry and add a new entry for the recipient.
11. Self-check consistency across the whole season:
    - Contestant ids match roster ids.
    - `final_week` is present and either `null` or equal to the latest elimination week.
    - Elimination outcomes and tribe membership timelines do not conflict.
    - Advantage lifecycle is internally consistent from obtain to end (or ongoing null end).

12. Return a concise summary of created/changed/fixed items and include source links.
