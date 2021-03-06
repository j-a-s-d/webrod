# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, tables, sets,
  xam,
  httprequest, httprequest_callbacks

type
  HandlerItem* = tuple[
    methods: HashSet[HttpMethod],
    handler: ReqHandler,
    validator: ReqValidator
  ]

  WebRodSimpleRouter* = object
    handlersList: Table[string, HandlerItem]

  SimpleRouter* = ref WebRodSimpleRouter

proc newSimpleRouter*(): SimpleRouter =
  result = new WebRodSimpleRouter
  result.handlersList = initTable[string, HandlerItem]()

proc options*(router: SimpleRouter, route: string): string =
  result = "HEAD,OPTIONS,TRACE"
  if router.handlersList.hasKey(route):
    for m in items(router.handlersList[route].methods):
      case m:
        of HttpGet: result &= ",GET"
        of HttpPut: result &= ",PUT"
        of HttpPost: result &= ",POST"
        of HttpDelete: result &= ",DELETE"
        else: discard

proc allowed*(router: SimpleRouter, route: string, httpMethod: HttpMethod): bool =
  router.handlersList.hasKey(route) and router.handlersList[route].methods.contains(httpMethod)

proc validate*(router: SimpleRouter, route: string, req: HttpRequest): bool =
  if router.handlersList.hasKey(route):
    let v = router.handlersList[route]
    return not assigned(v.validator) or v.validator(req)
  return false

proc has*(router: SimpleRouter, route: string): bool =
  router.handlersList.hasKey(route)

proc drop*(router: SimpleRouter, route: string) =
  router.handlersList.del(route)

proc drop*(router: SimpleRouter, reqHandler: ReqHandler) =
  for k, v in pairs(router.handlersList):
    if v.handler == reqHandler:
      router.handlersList.del(k)
      break

proc route*(router: SimpleRouter, reqHandler: ReqHandler): string =
  for k, v in pairs(router.handlersList):
    if v.handler == reqHandler:
      return k
  return STRINGS_EMPTY

proc set*(router: SimpleRouter, route: string, methods: openarray[HttpMethod], reqHandler: ReqHandler, reqValidator: ReqValidator) =
  router.handlersList[route] = (methods: toHashSet(methods), handler: reqHandler, validator: reqValidator)

proc get*(router: SimpleRouter, route: string): ReqHandler =
  if router.handlersList.hasKey(route): router.handlersList[route].handler else: nil
