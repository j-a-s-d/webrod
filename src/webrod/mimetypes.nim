# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  tables

const defaultContentType: string = "text/html"

type
  WebRodMimeTypes = object
    typesList: Table[string, string]
    defContentType: string

  MimeTypes* = ref WebRodMimeTypes

const
  DEFAULT_MIME_TYPES = {
    ".bin": "application/octet-stream",
    ".bmp": "image/bmp",
    ".bz2": "application/x-bzip2",
    ".css": "text/css",
    ".dtd": "application/xml-dtd",
    ".doc": "application/msword",
    ".gif": "image/gif",
    ".gz": "application/x-gzip",
    ".htm": "text/html",
    ".html": "text/html",
    ".jar": "application/java-archive",
    ".jpg": "image/jpeg",
    ".js": "application/javascript",
    ".json": "application/json",
    ".pdf": "application/pdf",
    ".png": "image/png",
    ".ppt": "application/powerpoint",
    ".ps": "application/postscript",
    ".rdf": "application/rdf",
    ".rtf": "application/rtf",
    ".sgml": "text/sgml",
    ".svg": "image/svg+xml",
    ".swf": "application/x-shockwave-flash",
    ".tar": "application/x-tar",
    ".tgz": "application/x-tar",
    ".tiff": "image/tiff",
    ".tsv": "text/tab-separated-values",
    ".txt": "text/plain",
    ".xls": "application/excel",
    ".xml": "application/xml",
    ".zip": "application/zip"
  }

proc newMimeTypes*(): MimeTypes =
  result = new WebRodMimeTypes
  result.typesList = initTable[string, string]()
  for item in items(DEFAULT_MIME_TYPES):
    result.typesList[item[0]] = item[1]
  result.defContentType = defaultContentType

proc set*(mimeTypes: MimeTypes, fileExtension: string, contentType: string) =
  mimeTypes.typesList[fileExtension] = contentType

proc get*(mimeTypes: MimeTypes, fileExtension: string): string =
  if mimeTypes.typesList.hasKey(fileExtension): mimeTypes.typesList[fileExtension] else: mimeTypes.defContentType

proc drop*(mimeTypes: MimeTypes, route: string) =
  mimeTypes.typesList.del(route)
