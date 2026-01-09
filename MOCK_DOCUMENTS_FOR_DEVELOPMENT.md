# Mock Documents for Colore Development

Development feature that returns realistic mock documents when a document doesn't exist, eliminating the need to copy production data.

## What It Does

```
Request for non-existent document → Returns realistic MOCK document
Request for created document → Returns real document from storage
```

Perfect for development: work with external documents without production data.

---

## Quick Start

### Get mock document (non-existent)
```bash
curl http://localhost:9240/document/app-1/doc-xyz
# Returns: Mock Document - doc-xyz
```

### Create real document
```bash
curl -X PUT -F "file=@test.txt" \
  http://localhost:9240/document/dev-app/my-doc/test.txt
```

### Get real document
```bash
curl http://localhost:9240/document/dev-app/my-doc
# Returns: actual document (not mock)
```

### Delete
```bash
curl -X DELETE http://localhost:9240/document/dev-app/my-doc
```

---

## Enable/Disable

### Development (Enable mocks)
```bash
# Edit: docker/colore/variables.env
MOCK_DOCUMENTS_ENABLED=true
RACK_ENV=development

# Rebuild
docker-compose up --build -d colore
```

### Production (Mocks auto-disabled for safety)
```bash
RACK_ENV=production
# Mocks automatically disabled - no action needed
```

---

## Key Features

### Supported File Types
- `.txt` - Text
- `.pdf` - PDF structure
- `.html` - HTML
- `.json` - JSON
- `.docx` - Word document
- Others - Text fallback

### What Works

| Operation | Mock | Real |
|-----------|------|------|
| GET document | ✅ | ✅ |
| GET file | ✅ | ✅ |
| POST title | ❌ | ✅ |
| POST version | ❌ | ✅ |
| DELETE | ⏭️ Ignored | ✅ |

Mock documents are read-only by design.

---

## How It's Implemented

### Files Created
- `lib/mock_document.rb` - Generates realistic mocks
- Tests - Unit and integration tests

### Files Modified
- `lib/config.rb` - Environment detection + production safety
- `lib/document.rb` - Returns mock if enabled
- `lib/app.rb` - Endpoint protections
- `config/app.yml` - Configuration
- `docker/colore/variables.env` - Set MOCK_DOCUMENTS_ENABLED

### Core Logic
```ruby
# When loading a document:
1. Check if exists on disk → Return real document
2. If not exists + MOCK_DOCUMENTS_ENABLED=true → Return mock
3. If not exists + not enabled → Return 404
```

---

## Production Safety

✅ **Automatic protection** - mocks cannot be used in production

```
Environment Detection (in config.rb)
  ↓
If RACK_ENV='production' → Force MOCK_DOCUMENTS_ENABLED=false
If RACK_ENV='development' → Use configured value
```

**Result:**
- Even if someone sets `MOCK_DOCUMENTS_ENABLED=true` in production by mistake
- Mocks are automatically disabled
- Application works normally (returns 404 for non-existent docs)
- No failures, no errors

---

## Ruby Integration Example

```ruby
class DocumentService
  def fetch_document(app_id, doc_id)
    response = HTTP.get("http://colore:9240/document/#{app_id}/#{doc_id}")
    JSON.parse(response.body)
    # Works with both mocks and real documents automatically
  end
  
  def create_document(app_id, doc_id, filename, file_content)
    HTTP.put(
      "http://colore:9240/document/#{app_id}/#{doc_id}/#{filename}",
      form: { file: file_content }
    )
  end
end
```

---

## Current Status

✅ Running in development with mocks enabled
```bash
RACK_ENV=development
MOCK_DOCUMENTS_ENABLED=true
```

✅ Tested and verified
- Mock documents return realistic structures
- Real documents work normally
- Hybrid flow seamless
- Production safety active

---

## Common Issues

**Getting 404 instead of mock?**
→ Check `MOCK_DOCUMENTS_ENABLED=true` in `docker/colore/variables.env`

**Can't update/delete mock?**
→ Intentional - mocks are read-only. Create real document instead.

**Want to verify?**
```bash
curl http://localhost:9240/document/test-app/any-id | jq .title
# If contains "Mock Document" → returns mock
```

---

## Testing

```bash
# All tests
rspec spec/lib/mock_document_spec.rb
rspec spec/integration/mock_document_spec.rb
```

---

## Summary

- ✅ Mock documents enabled in development
- ✅ No need to copy production database
- ✅ Hybrid flow: mocks + real documents coexist
- ✅ Automatic production safety
- ✅ Works transparently with client code
- ✅ Fully tested and working
