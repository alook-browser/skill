Initial read
Default read -> `bash scripts/page_read.sh "$TAB_ID" --token "$TOKEN"`
Article extraction -> `bash scripts/page_read.sh "$TAB_ID" --mode article --token "$TOKEN"`
Dynamic read -> `bash scripts/page_read.sh "$TAB_ID" --mode dynamic --token "$TOKEN"`
Cursor continuation -> `bash scripts/page_read.sh "$TAB_ID" --cursor "$CURSOR" --token "$TOKEN"`

Response read order
1. Read `ok`
2. `ok=false` -> read `error.code error.message error.hint error.details`
3. `ok=true` -> read `source`
4. Read `readType`
5. Read only the fields defined by that branch

Payload branches
`article + full -> title? blocks`
`page + full -> blocks`
`dynamic + full -> cursor stable turnState currentBlocks blocks`
`dynamic + delta -> cursor stable turnState currentBlocks changes`

Mode selection
Ordinary page reads -> default read
Explicit article extraction -> `--mode article`
Pages that will keep changing -> `--mode dynamic`
Existing dynamic continuation -> `--cursor "$CURSOR"`

Dynamic consumption
After a send, click, generate, load-more, or similar body-changing action, the next read step is `bash scripts/page_read.sh "$TAB_ID" --token "$TOKEN"`
`turnState=streaming` -> continue the same read path with the returned `cursor`
`turnState=settled` and non-empty `currentBlocks` -> consume `currentBlocks`

Fallback handoff
`PLAYBOOK_SAFE_FAILURE.md` handles `page_read.sh` failures and timeouts.
