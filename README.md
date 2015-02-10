Colore
======

Colore is a document storage, versioning and conversion system. Documents are stored on the filesystem, in a defined directory structure. Access to these documents is via API. Colore is intended to sit behind a proxying web server (e.g. Nginx), which can be used to directly access the documents, rather than putting that access load on Colore itself.

## Authentication

There is no authentication baked into Colore itself. The expectation is that this will be performed by the proxying web server.

## Directory structure

All Colore documents are stored in subdirectories under a single "storage" directory, which is defined in configuration. Beneath the storage directory documents are divided up by application - the expectation is that each application will keep to its own space when working on documents, though this is not enforced.

Under the application directory, documents are organised by "doc_id", which is defined by the application when storing documents. The overall directory structure is like this:

  {storage directory} - {app} - {doc_id} - metadata.json
                                         |
                                         - title
                                         |
                                         - current -> v002
                                         |
                                         - v001 - foo.docx
                                         |      |
                                         |      - foo.pdf
                                         |
                                         - v002 - foo.docx
                                                |
                                                - foo.jpg


As you can see, this document has two versions of foo.docx. The first version was converted to PDF and the second to an image. The current version is v002 - defined by the symlink "current". The metadata.json file is a JSON description of the directory structure.

API Definition
--------------

This is a simple JSON API. Requests are submitted generally as POSTS with form data. The response format depends on the request made, but are generally content type JSON.

Error responses are always JSON, and have this format:
{
  "status": {http error code},
  "description": "A description of the error"
}

### Create document

This method will create a new document, then perform the actions of Update document, below.

PUT /document/:app/:doc_id/:filename

Params: (suggest using multipart/form-data)
  file         - the uploaded file object (e.g. from &gt;input type="file"/&lt;
  title        - a description of the document (optional)
  actions      - an array of conversions to perform (optional)
  callback_url - a URL that Colore will call when the conversions are completed (optional)

#### Example:
Request:
  PUT /document/myapp/12345/foo.docx
    title=A test document
    actions=["pdf","oo"]
Response:
  {
    "status": 201,
    "description": "Document stored",
    "app": "mapp",
    "doc_id": "12345",
    "path": "/documents/myapp/12345/current/foo.docx"
  }

### Update document

This method will create a new version of an existing document and store the supplied file. If conversion actions are specified, these conversions will be scheduled to be performed asynchronously, and will POST to the optional callback_url when each is completed.

POST /document/:app/:doc_id/:filename

Params: (suggest using multipart/form-data)
  file         - the uploaded file object (e.g. from &gt;input type="file"/&lt;
  title        - a description of the document (optional)
  actions      - an array of conversions to perform (optional)
  callback_url - a URL that Colore will call when the conversions are completed (optional)

#### Example:
Request:
  POST /document/myapp/12345/foo.docx
    title=A test document
    actions=["pdf","oo"]
Response:
  {
    "status": 201,
    "description": "Document stored",
    "app": "mapp",
    "doc_id": "12345",
    "path": "/documents/myapp/12345/current/foo.docx"
  }

### Request new conversion

This method will request a new conversion be performed on a document version. Colore will do this asynchronously and will POST to the optional callback_url when completed.

POST /document/:app/:doc_id/:version/:filename/:action

Params: (suggest using multipart/form-data)
  version      - the version to convert (e.g. 'v001', or 'current')
  action       - the conversion to perform (e.g. pdf)
  callback_url - a URL that Colore will call when the conversions are completed (optional)

#### Example:
Request:
  POST /document/myapp/12345/current/foo.docx/pdf

Response:
  {
    "status": 202,
    "description": "Conversion initiated"
  }

### Delete document

This method will completely delete a document.

DELETE /document/:app/:doc_id

There are no parameters

#### Example:
Request:
  DELETE /document/myapp/12345

Response:
  {
    "status": 200,
    "description": "Document deleted"
  }

### Delete document version

This method will delete just one version of a document. It is not possible to delete the current version.

DELETE /document/:app/:doc_id/:version

#### Example:
Request:
  DELETE /document/myapp/12345/v001

Response:
  {
    "status": 200,
    "description": "Document version deleted"
  }

### Get file

This method will retrieve a document file, returning it as the response body. This method is really only meant for testing purposes, as in a live environment you would expect this to be performed by the proxying web server.

GET /document/:app/:doc_id/:version/:filename

#### Example:
Request:
  GET /document/myapp/12345/v001/foo.pdf

Response:
  Content-Type: application/pdf; charset=binary

  ... document body ...

### Get document info

This method will return a JSON object detailing the document contents.

GET /document/:app/:doc_id

#### Example:
Request:
  GET /document/myapp/12345

Response:
  {
    "status": 200,
    "description": "Information retrieved",
    "app": "myapp",
    "doc_id": "12345",
    "title": "Sample document",
    "current_version": "v002",
    "versions": {
      "v001": {
        "docx": {
          "content_type": "application/msword",
          "filename": "foo.docx",
          "path": "/document/myapp/12345/v001/foo.docx"
        }
        "pdf": {
          "content_type": "application/pdf; charset=binary",
          "filename": "foo.pdf",
          "path": "/document/myapp/12345/v001/foo.pdf"
        }
      },
      "v001": {
        "docx": {
          "content_type": "application/msword",
          "filename": "foo.docx",
          "path": "/document/myapp/12345/v001/foo.docx"
        }
        "txt": {
          "content_type": "text/plain; charset=us-ascii",
          "filename": "foo.txt",
          "path": "/document/myapp/12345/v001/foo.txt"
        }
      }
    }
  }

### Convert document

This is a foreground document conversion request. The converted document will be returned as the response body.

POST /convert

Params: (suggest using multipart/form-data)
  file      - the file to convert
  action    - the conversion to perform (e.g. 'pdf')
  language  - the file language (defaults to 'en')

#### Example:

POST /convert
  file=... foo.docx ...
  action=pdf
  language=en

Response:
  Content-Type: application/pdf; charset=binary

  ... PDF document body ...
