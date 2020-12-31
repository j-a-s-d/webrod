# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, os, oids,
  httprequest, mimetypes, simplerouter, standardcharsets

export
  httprequest, standardcharsets

const NAME: string = "webrod"
const VERSION: string = "0.1.0"

var
  defaultPort: int = 8080

proc getDefaultPort*(): int =
  defaultPort

proc setDefaultPort*(value: int) =
  defaultPort = value

type
  WebRodHttpHost = object
    name: string
    port: int
    listening: bool
    crossOrigin: bool
    staticFileServer: tuple[enabled: bool, route: string, folder: string]
    mimeTypes: MimeTypes
    router: SimpleRouter
    server: AsyncHttpServer
    id: string

  HttpHost* = ref WebRodHttpHost

proc newHttpHost*(): HttpHost =
  result = new WebRodHttpHost
  result.name = NAME & "/" & VERSION & " (" & hostOS & ")"
  result.port = defaultPort
  result.listening = false
  result.crossOrigin = false
  result.staticFileServer = (enabled: false, route: "", folder: ".")
  result.mimeTypes = newMimeTypes()
  result.router = newSimpleRouter()
  result.server = newAsyncHttpServer()
  result.id = $genOid();

proc getName*(hh: HttpHost): string =
  hh.name

proc setName*(hh: HttpHost, value: string) =
  hh.name = value

proc isListening*(hh: HttpHost): bool =
  hh.listening

proc getCrossOriginAllowance*(hh: HttpHost): bool =
  hh.crossOrigin

proc setCrossOriginAllowance*(hh: HttpHost, value: bool) =
  hh.crossOrigin = value

proc isStaticFileServingEnabled*(hh: HttpHost): bool =
  hh.staticFileServer.enabled

proc getStaticFileServingRoute*(hh: HttpHost): string =
  hh.staticFileServer.route

proc getStaticFileServingFolder*(hh: HttpHost): string =
  hh.staticFileServer.folder

proc enableStaticFileServing*(hh: HttpHost, route: string, folder: string) =
  hh.staticFileServer.enabled = route != "" and folder != ""
  hh.staticFileServer.folder = if hh.staticFileServer.enabled: folder else: "."
  hh.staticFileServer.route = if hh.staticFileServer.enabled: route else: ""

proc disableStaticFileServing*(hh: HttpHost) =
  enableStaticFileServing(hh, "", "")

proc getPort*(hh: HttpHost): int =
  hh.port

proc setPort*(hh: HttpHost, value: int) =
  hh.port = value

proc registerMimeType*(hh: HttpHost, fileExtension: string, contentType: string) =
  hh.mimeTypes.set(fileExtension, contentType)
  
proc unregisterMimeType*(hh: HttpHost, fileExtension: string) =
  hh.mimeTypes.drop(fileExtension)

proc registerHandlerForMethods(hh: HttpHost, methods: openarray[HttpMethod], route: string, reqHandler: ReqHandler) =
  hh.router.set(route, methods, reqHandler)

proc registerHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler) =
  hh.registerHandlerForMethods([HttpGet, HttpPost, HttpPut, HttpDelete], route, reqHandler)

proc registerGetHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler) =
  hh.registerHandlerForMethods([HttpGet], route, reqHandler)

proc registerPostHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler) =
  hh.registerHandlerForMethods([HttpPost], route, reqHandler)

proc registerPutHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler) =
  hh.registerHandlerForMethods([HttpPut], route, reqHandler)

proc registerDeleteHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler) =
  hh.registerHandlerForMethods([HttpDelete], route, reqHandler)

proc unregisterHandler*(hh: HttpHost, route: string) =
  hh.router.drop(route)

proc unregisterHandler*(hh: HttpHost, reqHandler: ReqHandler) =
  hh.router.drop(reqHandler)

proc isMethodAllowedForRoute*(hh: HttpHost, route: string, httpMethod: HttpMethod): bool =
  hh.router.allowed(route, httpMethod)

proc hasHandlerForRoute*(hh: HttpHost, route: string): bool =
  hh.router.has(route)

proc getHandlerForRoute*(hh: HttpHost, route: string): ReqHandler =
  hh.router.get(route)

proc getRouteForHandler*(hh: HttpHost, reqHandler: ReqHandler): string =
  hh.router.route(reqHandler)

proc handleStatic(hr: HttpRequest, path: string, mimeTypes: MimeTypes): Future[void] {.gcsafe.} =
  if not existsFile(path):
    return hr.replyNotFound()
  if fpOthersRead notin getFilePermissions(path):
    return hr.replyForbiddenAccess()
  return hr.replyOkAs(readFile(path), mimeTypes.get(splitFile(path).ext))

proc dispatchHandler(hh: HttpHost, hr: HttpRequest): Future[void] {.gcsafe.} =
  try:
    let rh = hh.router.get(hr.req.url.path)
    if rh != nil:
      case hr.req.reqMethod:
        of HttpHead:
          return hr.replyOk("")
        of HttpOptions:
          return hr.replyOk("", newHttpHeaders([("Allow", hh.router.options(hr.req.url.path))]))
        of HttpTrace:
          return hr.replyOk(hr.req.body)
        else:
          try:
            return if hh.router.allowed(hr.req.url.path, hr.req.reqMethod): rh(hr) else: hr.replyBadRequest()
          except:
            return hr.replyBadRequest();
    elif hh.staticFileServer.enabled:
      return handleStatic(hr, hh.staticFileServer.folder & hr.req.url.path & (if hr.req.url.path == "/": "index.htm" else: ""), hh.mimeTypes)
    return hr.replyNotFound()
  except:
    return hr.replyServerError()

proc start*(hh: HttpHost) =
  proc servingHandler(req: Request): Future[void] {.gcsafe.} =
    dispatchHandler(hh, newHttpRequest(hh.name, hh.id, hh.crossOrigin, req))
  asyncCheck hh.server.serve(Port(hh.port), servingHandler)
  hh.listening = true
  while hh.isListening():
    try:
      poll()
    except:
      hh.listening = false

proc stop*(hh: HttpHost): bool =
  hh.listening = false
  hh.server.close()
