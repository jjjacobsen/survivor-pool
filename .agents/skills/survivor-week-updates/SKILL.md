---
name: survivor-week-updates
description: Update static Survivor season data in db/seasons/season*.js for the next week. Use when asked to add or correct weekly eliminations, tribe changes, advantages, and final_week (including acquisition_notes, end_week, and end_notes rules).
---

# Survivor Week Updates

Use this workflow to extend season files with new weekly show events.

## Workflow

1. Read `docs/DB_schema.md`, `db/init.js`, and the target `db/seasons/season*.js` file.
2. Find the latest recorded week in `eliminations`, `tribeTimeline`, and `advantages`.
3. Collect sources for the target week from:
   - https://survivor.fandom.com/
   - https://www.truedorktimes.com/
4. Update `eliminations` with one entry per boot for that week.
5. Keep `final_week` accurate:
   - `final_week` is the last playable week for pool picks.
   - Keep `final_week` as `null` until the finale week is confirmed.
   - Once confirmed, set `final_week` to the same week as the latest elimination entry.
6. Update `tribeTimeline` only when tribe membership/state changes (`swap`, `merge`, etc.).
7. Update `advantages`:
   - Add entries for newly obtained advantages.
   - Keep `acquisition_notes` limited to how the advantage was obtained; never mention play/transfer/vote outcomes there.
   - Set `end_week` and `end_notes` when an advantage leaves the game (played, expired, transferred, voted out with it, or any other exit).
   - Keep `end_notes` as `null` when `end_week` is `null`.
   - When an advantage transfers in a later week, end the original entry and add a new entry for the recipient.
8. Preserve file style and structure:
   - Use `idOf("Name")` for contestant references.
   - Keep existing field names and ordering.
   - Keep `contestants[].age` as age at the time of that season (cast age), not current age; only change it if the stored season-time age is incorrect.
   - Do not rename existing constants or restructure the file.
9. Self-check:
   - Week numbers are correct and consistent.
   - `final_week` is present and either `null` or equal to the latest elimination week.
   - Eliminations align with tribe/merge state.
   - Advantage lifecycle is complete and internally consistent.
10. Return a concise summary of what changed and include source links.
