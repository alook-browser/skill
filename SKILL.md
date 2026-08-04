---
name: alook
description: "Use this skill when the user asks to open, read, navigate, click, type, inspect, screenshot, or otherwise operate a live page in Alook Browser; explicitly asks to use Alook/alook for a browser task; or continues an existing Alook/browser tab, window, login session, or page workflow. Use it for browser UI interaction when Alook is the available browser. Do not use it for Alook or WebKit source-code discussion, or static web research that does not require operating a live page."
license: Apache-2.0
compatibility: "Requires Alook Browser 1.0 or later with AI Control enabled."
metadata:
  alook-min-version: "1.0"
---
Alook browser skill entrypoint. Read this file first.

Playbooks
Page body reading -> `references/PLAYBOOK_PAGE_READ.md`
Cross-command recovery -> `references/PLAYBOOK_SAFE_FAILURE.md`
Web chat and cross-site relay -> `references/PLAYBOOK_SAFE_CHAT.md`

Command path
Use only public wrappers in `scripts`.
All wrapper paths are skill-root relative.
Host chat send and file delivery APIs are out of scope.

Response
Every wrapper prints one JSON object.
Success -> `ok=true`; wrapper exit code `0`.
Failure -> `ok=false`; wrapper exit code non-zero; read `error.code error.message error.retryable error.hint? error.details?`.
`error.retryable=true` means the server guarantees the original command produced no side effect and can be retried unchanged.
When the server cannot prove that guarantee, `error.retryable=false`.
When present, use `error.hint` as the single-command recovery instruction.
`TOKEN` defaults to `$ALOOK_ACCESS_TOKEN`, then `$SKILL_ACCESS_TOKEN`.
`field?` means optional.

Auth
Try token sources in order: `$ALOOK_ACCESS_TOKEN`, `$SKILL_ACCESS_TOKEN`, then the host agent's private persistent credential memory entry `alook.access-token`.
For each existing token -> `bash scripts/access_info.sh --token "$TOKEN"`.
Valid token -> pass `--token "$TOKEN"` to every command.
`error.code=access_token_not_found` -> discard `TOKEN`; if it came from credential memory, delete `alook.access-token`; continue with the next token source.
No valid token -> `bash scripts/access.sh "<agentName>"`; read `challengeId verificationCode expiresAt`.
Show `verificationCode` when the host asks for confirmation.
Then run `bash scripts/access_confirm.sh "$CHALLENGE_ID"`; read `accessToken trustMode`.
`access_confirm.sh` blocks until approval, rejection, or expiry.
`trustMode=once` -> keep `accessToken` in the current agent session; Alook accepts it until Skill stops.
`trustMode=always` -> before any browser command, save `accessToken` as `alook.access-token` in the host agent's private persistent credential memory; later and remote agent sessions must reuse it because the user may be away from the Mac and unable to approve another request.
Both tokens can call every public action.

Task and context
The access token is the permission boundary.
`windowId`, `splitId`, and `tabId` are global resource IDs.
`taskId` is an optional ownership label, filter, context marker, and cleanup unit; it is not a permission scope.
Omit `--task-id` when labeling or cleanup is unnecessary.
When `--task-id` is passed, it must identify an existing task or the action returns `task_not_found`.
Create a task with `task_begin.sh`; reuse it while the conversation continues the same browser work.
Passing `--task-id` to create or route actions labels created windows/splits and created or reused tabs.
Reusing a safe tab with `--task-id` transfers that tab into the task cleanup unit.
`task_end.sh --cleanup` closes labeled tabs and labeled windows/splits that contain no unlabeled tabs.
If the user cancels a window close prompt, cleanup returns `operation_failed`, preserves the task and remaining resource state, and sets `error.details.reason=user_cancelled`.

Target resolution
Known tab -> `tab_get.sh`, `tab_select.sh`, or a tab action with its `tabId`.
Current tab -> `tab_get_current.sh`.
Existing site or title -> `tab_find.sh`, then `bookmark_find.sh`, then `history_find.sh`.
New URL or blank tab -> `tab_open.sh`.
URL inputs must include a scheme; HTTP and HTTPS URLs must include a host.
Known bookmark or folder -> `bookmark_open.sh` or `bookmark_open_folder.sh`.
Creation without `--window-id` or `--split-id` uses the active window and split.
`tab_navigate.sh` takes URL as its positional argument; reload/back/forward take optional `tabId` and otherwise use the current tab.
`tab_wait.sh` and every DOM action require explicit `tabId`.

Safe tab reuse
`tab_open.sh URL`, `bookmark_open.sh`, and the first URL from `bookmark_open_folder.sh` reuse the selected tab only when all conditions hold: not loading, cannot go back, cannot go forward, and either URL is the internal homepage or URL is nil and the tab is not a popup.
Otherwise they create a tab.
`tab_open.sh` without URL always creates a blank tab.
Later URLs from `bookmark_open_folder.sh` always create tabs.

Readiness
Open, navigate, reload, back, and forward observe page readiness for 10000ms.
`loadState=ready` means the operation observed page `document.readyState` as `interactive` or `complete`.
`loadState=timeout` is an observation result, not an action error.
`documentReadyState` is the current tab readiness summary and may infer `complete` for idle blank or internal pages.
Use `tab_wait.sh <tabId> [--timeout MS]` to continue waiting; timeout range is `100...120000`, default `10000`.
`tab_wait.sh` timeout -> `ok=true loadState=timeout`.
Use `wait.sh` for DOM conditions; DOM wait timeout -> `ok=false operation_failed`.
Hard navigation failure -> `navigation_failed`.

Page reading
Use `page_read.sh` for body content and `page_snapshot.sh` for structure discovery.
After send, click, generate, load-more, or another body-changing action, call `page_read.sh` next.
`turnState=streaming` -> continue with the returned cursor.
`turnState=settled` with non-empty `currentBlocks` -> finish the dynamic read.
Navigation, JavaScript, and page interaction actions route later JavaScript dialogs to `dialog_get.sh` until the token is revoked, Skill stops, another token performs such an action on the tab, or the tab closes.
`dialog_get.sh state=pending` -> handle the dialog before dependent page actions.

Locator
`<locator>` is one of `<query>`, `--css CSS`, or `--role ROLE [--name NAME]`.
Single-target actions require exactly one match; follow `error.hint`, and use `query_all.sh` when candidate inspection is needed.
Sequential actions repeat the same locator form and value.
`click.sh` and `screenshot.sh` also accept `--point-json JSON`.
`drag.sh --from-json/--to-json` accepts point, query, css, or role/name JSON.
`keys.sh`, `scroll.sh`, and `screenshot.sh` may omit locator to target the page.

Text
Short text -> `--text TEXT`.
Text from file -> `--text-file FILE`.
Multiline, quoted, or shell-sensitive text -> `--text-stdin`.
Search actions accept either positional query or `--text-stdin`.

Artifacts
`screenshot.sh` returns `artifactId path downloadUrl mimeType expiresAt`.
Use artifacts immediately. `downloadUrl` is available no later than `expiresAt`; `path` is a temporary local file and is not an expiry boundary.

Schemas
`Tab` -> `tabId windowId splitId url title isLoading estimatedProgress documentReadyState isSelected isCurrentWindow isPinned canGoBack canGoForward hasEditableField isInteractive`
`TabMatch` -> `tabId windowId splitId url title isSelected isCurrentWindow hasEditableField isInteractive`
`TabMutation` -> `tabId windowId? splitId? url? title? created? navigated? loadState?`
`Window` -> `windowId isPrivate isFullscreen splitCount activeSplitId`
`Split` -> `splitId windowId tabCount selectedTabId`
`LayoutWindow` -> `windowId isPrivate isFullscreen frame activeSplitId splits(LayoutSplit[])`
`LayoutSplit` -> `splitId isActive selectedTabId tabs(LayoutTab[])`
`LayoutTab` -> `tabId url title isLoading estimatedProgress documentReadyState isPinned canGoBack canGoForward`
`BookmarkResult` -> `id kind bookmarkId? folderId? title folder? url? childrenCount? matchScore`
`HistoryEntry` -> `url title visitCount typedVisitCount matchScore lastVisit?`
`Choice` -> `id label tabId? bookmarkId? folderId? url?`
`Target` -> `tag text role rect? visible?`
`Rect` -> `x y w h`
`Block` -> `blockId? type? text? role? level? href?`
`Change` -> `insert? replace? append_text? remove?`
`Candidate` -> `tag text role rect?`
`Artifact` -> `artifactId path downloadUrl mimeType expiresAt`

Action reference

Check whether the local Skill service is reachable.
Usage: `health.sh`
Result: `ok`

Start a new access challenge for the named agent.
Usage: `access.sh <agentName>`
Result: `challengeId verificationCode expiresAt`

Complete an approved access challenge.
Usage: `access_confirm.sh <challengeId>`
Result: `accessToken trustMode`

Validate the token and inspect access state.
Usage: `access_info.sh [--token TOKEN]`
Result: `agentName trustMode activeTaskCount latestTaskId? latestTaskUpdatedAt? latestTaskLastTabTitle? latestTaskLastTabURL?`

Start a task label.
Usage: `task_begin.sh [--token TOKEN]`
Result: `taskId`

End a task; `--cleanup` closes task-owned tabs and task-owned windows/splits that contain no non-task tabs.
Usage: `task_end.sh <taskId> [--cleanup] [--token TOKEN]`
Result: `taskId ended cleanup`

Search bookmarks and folders.
Usage: `bookmark_find.sh (<query> | --text-stdin) [--kind item|folder|any] [--limit N] [--token TOKEN]`
Result: `query kind results(BookmarkResult[]) choices?(Choice[])`

Open one bookmark.
Usage: `bookmark_open.sh <bookmarkId> [--task-id ID] [--window-id ID] [--split-id ID] [--token TOKEN]`
Result: `TabMutation`

Open bookmarks from a folder.
Usage: `bookmark_open_folder.sh <folderId> [--task-id ID] [--window-id ID] [--split-id ID] [--recursive] [--url-contains TEXT] [--limit N] [--token TOKEN]`
Result: `folderId openedCount tabs(TabMutation[])`

Search history entries.
Usage: `history_find.sh (<query> | --text-stdin) [--time-range recent|today|week|month] [--limit N] [--token TOKEN]`
Result: `query timeRange entries(HistoryEntry[]) choices?(Choice[])`

List tabs globally or through filters.
Usage: `tab_list.sh [--task-id ID] [--window-id ID] [--split-id ID] [--token TOKEN]`
Result: `tabs(Tab[])`

Search tabs globally or through filters.
Usage: `tab_find.sh (<query> | --text-stdin) [--task-id ID] [--window-id ID] [--split-id ID] [--limit N] [--token TOKEN]`
Result: `query tabs(TabMatch[]) choices?(Choice[])`

Read the current active tab.
Usage: `tab_get_current.sh [--token TOKEN]`
Result: `tabId windowId splitId url title isLoading estimatedProgress documentReadyState isSelected isCurrentWindow`

Read one tab.
Usage: `tab_get.sh <tabId> [--token TOKEN]`
Result: `tabId windowId splitId url title isLoading estimatedProgress documentReadyState isSelected isCurrentWindow`

Open a URL or blank tab.
Usage: `tab_open.sh [URL] [--task-id ID] [--window-id ID] [--split-id ID] [--token TOKEN]`
Result: `TabMutation`

Close one tab.
Usage: `tab_close.sh <tabId> [--token TOKEN]`
Result: `tabId closed`

Make one tab active.
Usage: `tab_select.sh <tabId> [--token TOKEN]`
Result: `tabId selected`

Navigate an explicit tab or the current tab; `created=false`.
Usage: `tab_navigate.sh <url> [--tab-id ID] [--token TOKEN]`
Result: `TabMutation`

Reload one tab.
Usage: `tab_reload.sh [tabId] [--token TOKEN]`
Result: `tabId windowId splitId reloaded loadState`

Wait for a tab load state.
Usage: `tab_wait.sh <tabId> [--timeout MS] [--token TOKEN]`
Result: `tabId loadState`

Go back in one tab.
Usage: `tab_go_back.sh [tabId] [--token TOKEN]`
Result: `tabId wentBack loadState`

Go forward in one tab.
Usage: `tab_go_forward.sh [tabId] [--token TOKEN]`
Result: `tabId wentForward loadState`

Run JavaScript when no structured action covers the operation.
Usage: `tab_execute_js.sh <tabId> <script> [--await-promise] [--timeout MS] [--token TOKEN]`
Result: `result`

Click a target element or page point.
Usage: `click.sh <tabId> <locator> [--button left|right] [--click-count 1|2] [--token TOKEN]`
Result: `clicked button clickCount`

Move hover to a target element.
Usage: `hover.sh <tabId> <locator> [--token TOKEN]`
Result: `hovered synthetic`

Drag from one point or locator to another.
Usage: `drag.sh <tabId> --from-json JSON --to-json JSON [--steps N] [--duration-ms N] [--button left] [--token TOKEN]`
Result: `dragged synthetic fromPoint? toPoint?`

Set editable field content in one step; main text-entry path.
Usage: `input.sh <tabId> <locator> (--text TEXT | --text-file FILE | --text-stdin) [--token TOKEN]`
Result: `typed valueLength?`

Type text into an editable field when keystroke events are required.
Usage: `type.sh <tabId> <locator> (--text TEXT | --text-file FILE | --text-stdin) [--clear] [--token TOKEN]`
Result: `typed valueLength?`

Read the uniquely matching element.
Usage: `read.sh <tabId> <locator> [--mode text|html|attrs] [--fields CSV] [--text-limit N] [--token TOKEN]`
Result: `result method truncated?`

List matching elements.
Usage: `query_all.sh <tabId> <locator> [--limit N] [--fields CSV] [--text-limit N] [--token TOKEN]`
Result: `count returned elements(Candidate[])`

Resolve the uniquely matching element.
Usage: `find.sh <tabId> <locator> [--token TOKEN]`
Result: `target(Target)`

Read the last matching element.
Usage: `read_last_matching.sh <tabId> <locator> [--mode text|html|attrs] [--fields CSV] [--text-limit N] [--token TOKEN]`
Result: `result method truncated?`

Scroll the page or a target element.
Usage: `scroll.sh <tabId> [<locator>] [--direction up|down|left|right] [--amount N] [--token TOKEN]`
Result: `scrolled direction amount target?`

Wait for a target condition.
Usage: `wait.sh <tabId> <locator> [--timeout MS] [--mode exists|visible|text|count|enabled|disabled|removed|textstable] [--text TEXT | --text-file FILE | --text-stdin] [--count N] [--stable-time MS] [--token TOKEN]`
Result: `found waitedMs stableTimeMs?`

Capture a screenshot of the page, uniquely matching target, or point.
Usage: `screenshot.sh <tabId> [<locator>] [--point-json JSON] [--format png|jpeg] [--quality N] [--scale N] [--token TOKEN]`
Result: `Artifact matched? target?(Target)`

Send a key or key chord.
Usage: `keys.sh <tabId> <key> [<locator>] [--modifiers CSV] [--token TOKEN]`
Result: `pressed key?`

Upload files through a file input element.
Usage: `upload.sh <tabId> <locator> --path FILE [--path FILE ...] [--token TOKEN]`
Result: `uploaded fileNames`

Read structured page body blocks.
Usage: `page_read.sh <tabId> [--cursor CURSOR] [--mode article|dynamic] [--token TOKEN]`
Result: `source readType blocks?(Block[]) currentBlocks?(Block[]) changes?(Change[]) cursor? stable? turnState? title?`

Read a structure snapshot.
Usage: `page_snapshot.sh <tabId> [--selector SELECTOR] [--token TOKEN]`
Result: `url title blocks(Block[]) snapshotId? preferredRegionCandidateRef? regionCandidates?(Candidate[]) truncated?`

Read active JavaScript dialog state.
Usage: `dialog_get.sh <tabId> [--token TOKEN]`
Result: `state hasDialog type? message? defaultText?`

Accept or dismiss the pending JavaScript dialog.
Usage: `dialog_handle.sh <tabId> <accept|dismiss> [--text TEXT | --text-file FILE | --text-stdin] [--token TOKEN]`
Result: `handled decision`

List browser windows.
Usage: `window_list.sh [--task-id ID] [--token TOKEN]`
Result: `windows(Window[])`

Create a browser window; use without `--url` when recovering `no_active_context`.
Usage: `window_create.sh [--task-id ID] [--private] [--url URL] [--token TOKEN]`
Result: `windowId created`

Close one browser window; closes all tabs and splits in that window. User cancellation returns `operation_failed` with `error.details.reason=user_cancelled`.
Usage: `window_close.sh <windowId> [--token TOKEN]`
Result: `windowId closed`

Focus one browser window.
Usage: `window_focus.sh <windowId> [--token TOKEN]`
Result: `windowId focused`

List browser splits.
Usage: `split_list.sh [--task-id ID] [--window-id ID] [--token TOKEN]`
Result: `splits(Split[])`

Create a browser split.
Usage: `split_create.sh [--task-id ID] [--window-id ID] [--url URL] [--token TOKEN]`
Result: `splitId windowId created`

Close one browser split; closes all tabs in that split. Closing the last split uses the window close confirmation path.
Usage: `split_close.sh <splitId> [--token TOKEN]`
Result: `splitId closed`

Read current window, split, and tab layout.
Usage: `layout_snapshot.sh [--task-id ID] [--token TOKEN]`
Result: `revision windows(LayoutWindow[])`
