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

## Troubleshooting

- **Jina fails**: Use `web_fetch` as fallback
- **Bad characters in title**: Script sanitizes automatically
- **File exists**: Appends timestamp suffix
