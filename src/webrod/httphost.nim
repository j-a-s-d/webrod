# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, os,
  xam,
  mimetypes, simplerouter

reexport(httpstand, httpstand)
reexport(httprequest, httprequest)
reexport(httprequest_callbacks, httprequest_callbacks)
reexport(httprequest_validators, httprequest_validators)
reexport(standardcharsets, standardcharsets)

let
  NAME*: string = "webrod"
  VERSION*: SemanticVersion = newSemanticVersion(0, 4, 1)

var
  defaultPort: int = 8080

proc getDefaultPort*(): int =
  defaultPort

proc setDefaultPort*(value: int) =
  defaultPort = value

const
  ALLOW: string = "Allow"
  INDEX_HTM: string = "index.htm"

type
  WebRodHttpHost = object
    staticFileServer: tuple[enabled: bool, route: string, folder: string]
    mimeTypes: MimeTypes
    router: SimpleRouter
    stand: HttpStand

  HttpHost* = ref WebRodHttpHost

proc newHttpHost*(): HttpHost =
  result = new WebRodHttpHost
  result.staticFileServer = (enabled: false, route: STRINGS_EMPTY, folder: STRINGS_PERIOD)
  result.mimeTypes = newMimeTypes()
  result.router = newSimpleRouter()
  result.stand = newHttpStand(NAME & STRINGS_SLASH & $VERSION & STRINGS_SPACE & parenthesize(hostOS), defaultPort)

proc getStand*(hh: HttpHost): HttpStand =
  hh.stand

proc getProcessedRequestsAmountSinceCreation*(hh: HttpHost): int =
  hh.stand.getProcessedRequestsAmountSinceCreation()

proc getElapsedMinutesSinceCreation*(hh: HttpHost): float =
  hh.stand.getElapsedMinutesSinceCreation()

proc getElapsedMinutesSinceCreationAsString*(hh: HttpHost, appendix: string = STRINGS_LOWERCASE_M): string =
  hh.stand.getElapsedMinutesSinceCreationAsString(appendix)

proc getId*(hh: HttpHost): string =
  hh.stand.getId()

proc getPort*(hh: HttpHost): int =
  hh.stand.getPort()

proc setPort*(hh: HttpHost, value: int) =
  hh.stand.setPort(value)

proc getName*(hh: HttpHost): string =
  hh.stand.getName()

proc setName*(hh: HttpHost, value: string) =
  hh.stand.setName(value)

proc isListening*(hh: HttpHost): bool =
  hh.stand.isListening()

proc hasError*(hh: HttpHost): bool =
  hh.stand.hasError()

proc getErrorMessage*(hh: HttpHost): string =
  hh.stand.getErrorMessage()

proc getCrossOriginAllowance*(hh: HttpHost): bool =
  hh.stand.getCrossOriginAllowance()

proc setCrossOriginAllowance*(hh: HttpHost, value: bool) =
  hh.stand.setCrossOriginAllowance(value)

proc isStaticFileServingEnabled*(hh: HttpHost): bool =
  hh.staticFileServer.enabled

proc getStaticFileServingRoute*(hh: HttpHost): string =
  hh.staticFileServer.route

proc getStaticFileServingFolder*(hh: HttpHost): string =
  hh.staticFileServer.folder

proc enableStaticFileServing*(hh: HttpHost, route: string, folder: string) =
  hh.staticFileServer.enabled = route != STRINGS_EMPTY and folder != STRINGS_EMPTY
  hh.staticFileServer.folder = if hh.staticFileServer.enabled: folder else: STRINGS_PERIOD
  hh.staticFileServer.route = if hh.staticFileServer.enabled: route else: STRINGS_EMPTY

proc disableStaticFileServing*(hh: HttpHost) =
  enableStaticFileServing(hh, STRINGS_EMPTY, STRINGS_EMPTY)

proc registerMimeType*(hh: HttpHost, fileExtension: string, contentType: string) =
  hh.mimeTypes.set(fileExtension, contentType)

proc unregisterMimeType*(hh: HttpHost, fileExtension: string) =
  hh.mimeTypes.drop(fileExtension)

proc registerHandlerForMethods(hh: HttpHost, methods: openarray[HttpMethod], route: string, reqHandler: ReqHandler, reqValidator: ReqValidator) =
  hh.router.set(route, methods, reqHandler, reqValidator)

proc registerHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler, reqValidator: ReqValidator = nil) =
  hh.registerHandlerForMethods([HttpGet, HttpPost, HttpPut, HttpDelete], route, reqHandler, reqValidator)

proc registerGetHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler, reqValidator: ReqValidator = nil) =
  hh.registerHandlerForMethods([HttpGet], route, reqHandler, reqValidator)

proc registerPostHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler, reqValidator: ReqValidator = nil) =
  hh.registerHandlerForMethods([HttpPost], route, reqHandler, reqValidator)

proc registerPutHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler, reqValidator: ReqValidator = nil) =
  hh.registerHandlerForMethods([HttpPut], route, reqHandler, reqValidator)

proc registerDeleteHandler*(hh: HttpHost, route: string, reqHandler: ReqHandler, reqValidator: ReqValidator = nil) =
  hh.registerHandlerForMethods([HttpDelete], route, reqHandler, reqValidator)

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
    if assigned(rh):
      case hr.req.reqMethod:
        of HttpHead:
          return hr.replyOk(STRINGS_EMPTY)
        of HttpOptions:
          return hr.replyOk(STRINGS_EMPTY, newHttpHeaders([(ALLOW, hh.router.options(hr.req.url.path))]))
        of HttpTrace:
          return hr.replyOk(hr.req.body)
        else:
          if not hh.router.allowed(hr.req.url.path, hr.req.reqMethod):
            return hr.replyBadRequest()
          if not hh.router.validate(hr.req.url.path, hr):
            return hr.replyBadRequest()
          try:
            return rh(hr)
          except:
            return hr.replyBadRequest()
    elif hh.staticFileServer.enabled:
      return handleStatic(hr, hh.staticFileServer.folder & hr.req.url.path & (
        if hr.req.url.path == STRINGS_SLASH: INDEX_HTM else: STRINGS_EMPTY
      ), hh.mimeTypes)
    return hr.replyNotFound()
  except:
    return hr.replyServerError()

proc start*(hh: HttpHost) =
  proc servingHandler(req: Request): Future[void] {.gcsafe.} =
    dispatchHandler(hh, newHttpRequest(hh.stand, req))
  hh.stand.listen(servingHandler)

proc stop*(hh: HttpHost): bool =
  hh.stand.close()
