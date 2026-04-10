---
name: pdf-extract
description: Extract text from PDF files on the Mac mini. Handles environment quirks (no poppler, terminal blocks, user-site pymupdf).
trigger: User sends a PDF file or asks to read/extract/analyze a PDF document.
---

# PDF Text Extraction

Extract text from PDF files on the Mac mini environment.

## Environment Quirks

- **No poppler** (`pdftotext` not available) — don't try it
- **No pre-installed PDF Python libs** (fitz/pdfminer/pdfplumber/PyPDF2/pypdf all missing)
- **Terminal `python3 -c` commands get blocked/timeout** for imports — use `execute_code` instead
- pymupdf installs to user site-packages: `/Users/homemac/Library/Python/3.9/lib/python/site-packages`

## Steps

### 1. Ensure pymupdf is installed

```python
from hermes_tools import terminal
result = terminal('pip3 install pymupdf --quiet 2>&1 | tail -3', timeout=120)
```

### 2. Extract text via execute_code

```python
import sys
sys.path.insert(0, '/Users/homemac/Library/Python/3.9/lib/python/site-packages')
import fitz

pdf_path = '/path/to/file.pdf'
doc = fitz.open(pdf_path)
print(f'Total pages: {len(doc)}')

all_text = []
for i, page in enumerate(doc):
    text = page.get_text()
    if text.strip():
        all_text.append(f'--- Page {i+1} ---\n{text}')

full = '\n'.join(all_text)
print(full[:15000])  # first chunk
```

For large PDFs, split into multiple `execute_code` calls with offset slicing of `full`.

### 3. For scanned/image PDFs (no extractable text)

Use `vision_analyze` on individual page screenshots, or use the `ocr-and-documents` skill.

## Pitfalls

- `web_extract` cannot handle `file://` URLs — blocked as private network
- Terminal `python3` commands importing libs often timeout — always use `execute_code`
- Remember `sys.path.insert` before `import fitz` or it won't find the user-installed package
- Very long PDFs (50+ pages) may need chunked printing to stay within output limits
