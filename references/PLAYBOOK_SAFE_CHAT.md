Chat page resolution
Known `tabId` -> `tab_get.sh` / `tab_select.sh` / `tab_navigate.sh --tab-id`
Current page -> `tab_get_current.sh`
User explicitly wants an existing chat tab -> `tab_find.sh` -> `tab_select.sh`
Otherwise resolve in this order -> `bookmark_find.sh` -> `bookmark_open.sh` -> `history_find.sh` -> `tab_open.sh`
Use `--task-id "$TASK_ID"` on open/create actions when cleanup ownership is needed.

Editor readiness
`bash scripts/wait.sh "$TAB_ID" --css "textarea, input, [contenteditable='true']" --mode exists --timeout 10000 --token "$TOKEN"`

Input path
Short text -> `bash scripts/input.sh "$TAB_ID" --css "textarea, input, [contenteditable='true']" --text "$TEXT" --token "$TOKEN"`
Long or multiline text -> `printf '%s' "$TEXT" | bash scripts/input.sh "$TAB_ID" --css "textarea, input, [contenteditable='true']" --text-stdin --token "$TOKEN"`

Submit path
Known send-button selector -> `bash scripts/click.sh "$TAB_ID" --css "$SEND_SELECTOR" --token "$TOKEN"`
Default submit -> `bash scripts/keys.sh "$TAB_ID" Enter --token "$TOKEN"`
User explicitly wants Command+Enter -> `bash scripts/keys.sh "$TAB_ID" Enter --modifiers command --token "$TOKEN"`

Read path after send
When the send action returns `ok=true`, the next read step is `bash scripts/page_read.sh "$TAB_ID" --token "$TOKEN"`
`source=page` or `source=article` -> consume the returned blocks
`source=dynamic` and `readType=full` -> read `cursor stable turnState currentBlocks blocks`
`source=dynamic` and `turnState=streaming` -> `bash scripts/page_read.sh "$TAB_ID" --cursor "$CURSOR" --token "$TOKEN"`
`source=dynamic` and `turnState=settled` and non-empty `currentBlocks` -> use `currentBlocks` as the answer for this turn
Cross-site relay forwards `currentBlocks` to the next site.

Wait budget
Track total wait time from the first `page_read.sh` call through every later `--cursor` continuation.
If `60000ms` passes without settled non-empty `currentBlocks`, switch to `PLAYBOOK_SAFE_FAILURE.md`.

Target reuse
Sequential target actions repeat the same original `query/css/role`.

Screenshot checks
Targeted screenshot -> `find.sh` and `screenshot.sh` repeat the same original `query/css/role`
Omitting the locator in `screenshot.sh` captures the page.
If the screenshot result reports `target_rect_invalid` or `target_rect_too_large`, refine the locator and run the pair again with the same locator form.

Cleanup
User explicitly asks for cleanup -> `bash scripts/task_end.sh "$TASK_ID" --cleanup --token "$TOKEN"`
