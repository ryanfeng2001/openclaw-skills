# Learning Examples

## Good Pattern Example

```markdown
## 2026-03-31 Pattern: aria2c HF Download

**Context:** HuggingFace large file downloads (>1GB) fail repeatedly with curl and Python huggingface_hub due to rate limiting and connection resets.
**Solution:** Use aria2c with 8 connections from hf-mirror.com: `aria2c -x 8 -s 8 <url>`. Achieves 80MB/s vs single-stream 5MB/s that keeps dying.
**Why:** Multi-connection splits the file into chunks, surviving individual connection failures. hf-mirror.com is China-optimized CDN.
**Confidence:** high
**Reuse count:** 3
**Tags:** download, huggingface, aria2c, china
```

## Bad Pattern Example (Don't Save)

```markdown
## Pattern: Use curl for Downloads
**Context:** Needed to download a file
**Solution:** Used curl
**Why:** It works
```

Why bad: Obvious, no specificity, no real insight.

## Good Instinct Example

```markdown
### HF Large File Download
- **Rule:** For HuggingFace files >500MB, always use `aria2c -x 8 -s 8` from `hf-mirror.com`. Never use Python snapshot_download for large files.
- **Origin:** 2026-03-31, failed 5 times with Python, aria2c finished in 1 min
- **Confidence:** high
- **Evidence:** Qwen3.5-9B 5GB download, camoufox 298MB, multiple model downloads
```
