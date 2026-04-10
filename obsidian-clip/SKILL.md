---
name: obsidian-clip
description: Save web pages to Obsidian Vault as Markdown. Trigger when user says "clip", "save to obsidian", "#clip", "剪藏", "保存网页", or shares a URL with clip intent. Also use when user wants to configure or set up web-to-Obsidian clipping workflow.
---

# Obsidian Clip

Save any web page as clean Markdown to your Obsidian Vault Inbox.

## Quick Usage

User sends a message like:
- `#clip https://example.com 文章标题`
- `clip https://zhuanlan.zhihu.com/p/12345`
- `保存这个网页 https://...`

## Steps

### 1. Parse Input

Extract from the message:
- **URL** (required) — the web page link
- **Title** (optional) — user-provided title, defaults to page title or timestamp
- **Tags** (optional) — e.g. `#clip #ai #paper`

Pattern: `#clip[#tag...] URL [title]`

### 2. Fetch & Save

Run the clip script:

```bash
bash {{SKILL_DIR}}/scripts/clip.sh "<URL>" "<TITLE>"
```

The script uses Jina Reader (`https://r.jina.ai/`) to extract clean Markdown from any URL.

### 3. Confirm

Reply with: `✅ 已保存到 Obsidian Inbox: <title>.md`

If fetching fails, try `web_fetch` tool as fallback, then write the content directly.

### 4. Optional Enhancements

If tags were provided, prepend them to the saved file:

```bash
echo -e "---\ntags: [tag1, tag2]\nsource: URL\n---\n$(cat FILE)" > FILE
```

If user wants AI summary, read the saved file and append a summary section.

## Configuration

Vault path is configured in the script. Default: `/Volumes/satachi/macobi/macobi/Inbox`

To change, edit `scripts/clip.sh` and set `VAULT_DIR`.

## WeChat Articles (Camofox)

WeChat articles (mp.weixin.qq.com) block Jina/curl — must use Camofox browser (anti-detection).

Camofox runs as a LaunchAgent on port 9377. API base: `http://localhost:9377`

### Steps

1. **Create tab** (both `userId` AND `sessionKey` required):
   ```bash
   curl -s -X POST http://localhost:9377/tabs \
     -H 'Content-Type: application/json' \
     -d '{"url":"<WECHAT_URL>","userId":"clip","sessionKey":"default"}'
   ```
   Returns `{"tabId":"...","url":"..."}`.

2. **Scroll** to trigger lazy-loaded images (8 iterations with 1s gaps works well):
   ```bash
   for i in 1 2 3 4 5 6 7 8; do
     curl -s -X POST "http://localhost:9377/tabs/<tabId>/scroll" \
       -H 'Content-Type: application/json' \
       -d '{"direction":"down","amount":800}' > /dev/null
     sleep 1
   done
   ```

3. **Extract article metadata + images** via evaluate (`userId` goes in JSON body, not query param):
   ```javascript
   (() => {
     const title = document.querySelector('#activity-name')?.textContent?.trim() || '';
     const author = document.querySelector('#js_name')?.textContent?.trim() || '';
     const date = document.querySelector('#publish_time')?.textContent?.trim() || '';
     const imgs = document.querySelectorAll('img');
     const imgData = [];
     imgs.forEach((img, i) => {
       const src = img.dataset.src || img.src || '';
       if (src && (src.includes('mmbiz') || src.includes('qpic'))) {
         imgData.push({i: i, src: src});
       }
     });
     return JSON.stringify({title, author, date, n: imgData.length, images: imgData});
   })()
   ```
   Send via: write JSON payload to `/tmp/camo_payload.json`, then `curl -d @/tmp/camo_payload.json`.
   Use `img.dataset.src` first — WeChat lazy-loads via `data-src` attribute.

4. **Extract article content as structured blocks** (avoids JSON escaping issues with raw HTML):
   ```javascript
   (() => {
     const content = document.querySelector('#js_content');
     const blocks = [];
     const walk = (node) => {
       if (node.nodeType === 3) {
         const t = node.textContent.trim();
         if (t) blocks.push({type:'text', content:t});
         return;
       }
       if (node.nodeType !== 1) return;
       const tag = node.tagName.toLowerCase();
       if (tag === 'img') {
         const src = node.dataset.src || node.src || '';
         if (src && (src.includes('mmbiz')||src.includes('qpic')))
           blocks.push({type:'img', src:src});
         return;
       }
       if (tag === 'strong' || tag === 'b') {
         const t = node.textContent.trim();
         if (t) blocks.push({type:'bold', content:t});
         return;
       }
       if (tag === 'br') return;
       for (const child of node.childNodes) walk(child);
       if (['p','h1','h2','h3','h4','section'].includes(tag))
         blocks.push({type:'break'});
     };
     for (const child of content.childNodes) walk(child);
     return JSON.stringify({title, author, date, blocks});
   })()
   ```

5. **Download images** via proxy (mmbiz.qpic.cn needs proxy from this environment):
   ```bash
   curl -s -o img_NN.jpg \
     -x http://192.168.66.166:7890 \
     -H "Referer: https://mp.weixin.qq.com/" \
     -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "<mmbiz_url>"
   ```
   Then filter: keep JPG ≥100KB, delete the rest. Match downloaded images back to blocks by full URL comparison.

6. **Build Markdown** from blocks: iterate blocks, for `img` blocks check if URL matches a downloaded file, for `text`/`bold`/`break` blocks emit corresponding Markdown. Clean up multiple blank lines with `re.sub(r'\n{3,}', '\n\n', md)`.

7. **Save** to `~/Obsidian/Inbox/剪藏/<公众号名>/<文章名>/` — md and images in same directory.

8. **Cleanup**: `curl -X DELETE "http://localhost:9377/tabs/<tabId>?userId=clip&sessionKey=default"`

### Image Filter Rules
- Skip PNG unless >500KB
- Only keep JPG ≥100KB
- Delete images below threshold after download
- Match images to article position by full URL comparison

### Key Pitfalls
- **Create tab requires `sessionKey`**: `"sessionKey":"default"` — without it you get `userId and sessionKey required` error
- **Evaluate requires `userId` in JSON body**: NOT in query params. Write payload to temp file to avoid shell escaping hell: `curl -d @/tmp/camo_payload.json`
- **Do NOT extract raw innerHTML**: It causes JSON control character errors. Use the structured blocks approach instead.
- **Use `img.dataset.src` not `img.currentSrc`**: WeChat lazy-loads via `data-src` attribute; `dataset.src` is more reliable.
- **Tabs get garbage collected fast**: If a tab returns "Tab not found", recreate it. Complete all operations promptly.
- **Must scroll before extracting images**: WeChat lazy-loads them. 8 scrolls × 800px with 1s gaps works well.
- **Download needs proxy**: mmbiz.qpic.cn URLs require `-x http://192.168.66.166:7890` and Referer header from this environment.
- Some images are decorative/emoji (< 5KB) — always filter by size after download

## Troubleshooting

- **Jina fails**: Use `web_fetch` as fallback
- **WeChat / anti-bot sites**: Use Camofox path above
- **Bad characters in title**: Script sanitizes automatically
- **File exists**: Appends timestamp suffix
