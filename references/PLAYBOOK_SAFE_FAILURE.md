Read `error.code error.message error.retryable error.hint error.details`.
Follow `error.hint` for the failed command.
Retry the original command unchanged only when `error.retryable=true`.

Auth recovery
`missing_access_token` or `access_token_not_found` -> run `access.sh`, then `access_confirm.sh`, then repeat the interrupted command with the new token.
`access_challenge_not_found` or `challenge_expired` -> restart `access.sh`.
`challenge_denied` or `skill_disabled` -> stop.

Fresh page read
`cursor_invalid`, `cursor_stale`, `dynamic_read_required`, `region_not_found`, `region_stale`, or `region_limit_reached` -> run `bash scripts/page_read.sh "$TAB_ID" --token "$TOKEN"` without cursor or mode.
`candidate_stale` -> repeat the discovery action.
`frame_unreachable` -> run `page_snapshot.sh`, then choose a reachable target.

Body fallback
When `page_read.sh` cannot provide required content, run `bash scripts/read.sh "$TAB_ID" --css "main" --mode text --token "$TOKEN"`.
If structure or visual confirmation is still required, run `find.sh` and `screenshot.sh` with the same `--css "main"` locator.
Label fallback content `fallback result`.
