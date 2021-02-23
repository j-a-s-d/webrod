# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asyncdispatch,
  httprequest

type
  HttpRequestCallback*[T] = proc (hr: HttpRequest): T {.gcsafe.}

  ReqHandler* = HttpRequestCallback[Future[void]]

  ReqValidator* = HttpRequestCallback[bool]
