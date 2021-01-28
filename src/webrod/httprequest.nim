# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, uri, cookies, times, json, strtabs, strutils,
  xam,
  httpstand, standardcharsets

const
  DATE: string = "Date"
  DATE_FORMATTING_VALUE: string = "ddd, yyyy-MM-dd hh:mm:ss 'GMT'"
  NO_CACHE_CONTROL: string = "no-cache, no-store, max-age=0"
  CACHE_CONTROL: string = "Cache-Control"
  CONTENT_TYPE: string = "Content-Type"
  COOKIE: string = "Cookie"
  COOKIE2: string = "Cookie2"
  SET_COOKIE: string = "Set-Cookie"
  SERVER: string = "Server"
  LOCATION: string = "Location"

type
  HttpRequest* = object
    started: float
    created: float
    req*: Request
    hostid*: string
    stand: HttpStand
    cookies: StringTableRef
    defCharset: string

  ReqHandler* = proc (req: HttpRequest): Future[void] {.gcsafe.}

proc newHttpRequest*(stand: HttpStand, req: Request): HttpRequest =
  result.started = cpuTime()
  result.created = epochTime()
  result.cookies = newStringTable()
  result.stand = stand
  result.hostid = stand.getId()
  result.req = req
  result.defCharset = getDefaultCharset()

proc getStand*(hr: HttpRequest): HttpStand =
  hr.stand

proc getCPUTimeSpent*(hr: HttpRequest): float =
  cpuTime() - hr.started

proc getCPUTimeSpentAsString*(hr: HttpRequest, decimals: int = 3, appendix: string = STRINGS_LOWERCASE_S): string =
  getCPUTimeSpent(hr).formatFloat(format = ffDecimal, precision = decimals) & appendix

proc getRequestElapsedTime*(hr: HttpRequest): float =
  epochTime() - hr.created

proc getRequestElapsedTimeAsString*(hr: HttpRequest, decimals: int = 3, appendix: string = STRINGS_LOWERCASE_S): string =
  getRequestElapsedTime(hr).formatFloat(format = ffDecimal, precision = decimals) & appendix

proc getRequestBodyAsJson*(hr: HttpRequest): JsonNode =
  try:
    parseJson(hr.req.body)
  except:
    nil

proc getRequestQueryStringAsStringTable*(hr: HttpRequest): StringTableRef =
  result = newStringTable()
  let qsp = hr.req.url.query.split(STRINGS_AMPERSAND)
  for i in 0..high(qsp):
    let tmp = qsp[i].split(STRINGS_EQUAL)
    if tmp.len == 2:
      result[tmp[0]] = tmp[1]

proc getRequestCookiesAsStringTable*(hr: HttpRequest): StringTableRef =
  if hr.req.headers.hasKey(COOKIE):
    parseCookies(hr.req.headers[COOKIE])
  elif hr.req.headers.hasKey(COOKIE2): # NOTE: see RFC 2965
    parseCookies(hr.req.headers[COOKIE2])
  else:
    newStringTable()

proc clearResponseCookies*(hr: HttpRequest) =
  hr.cookies.clear(modeCaseSensitive)

proc addResponseCookies*(hr: HttpRequest, cookieTable: StringTableRef) =
  for k, v in cookieTable:
    hr.cookies[k] = encodeUrl(v, true)

proc reply*(hr: HttpRequest, httpCode: HttpCode, textContent: string, httpHeaders: HttpHeaders = newHttpHeaders()) {.async.} =
  httpHeaders[DATE] = now().utc.format(DATE_FORMATTING_VALUE)
  httpHeaders[SERVER] = hr.stand.getName()
  if not httpHeaders.hasKey(CACHE_CONTROL):
    httpHeaders[CACHE_CONTROL] = NO_CACHE_CONTROL
  if hr.stand.getCrossOriginAllowance():
    httpHeaders["Access-Control-Allow-Origin"] = STRINGS_ASTERISK
  if len(hr.cookies) > 0:
    var c: seq[string] = @[]
    for k, v in hr.cookies:
      c.add(k & STRINGS_EQUAL & v & STRINGS_SEMICOLON)
    httpHeaders[SET_COOKIE] = c
  await hr.req.respond(httpCode, textContent, httpHeaders)

proc replyOk*(hr: HttpRequest, textContent: string, httpHeaders: HttpHeaders = newHttpHeaders()) {.async.} =
  await hr.reply(Http200, textContent, httpHeaders)

proc replyOkAs*(hr: HttpRequest, textContent: string, contentType: string, contentCharset: string) {.async.} =
  await hr.replyOk(textContent, newHttpHeaders([(CONTENT_TYPE, contentType & "; charset=" & contentCharset)]))

proc replyOkAs*(hr: HttpRequest, textContent: string, contentType: string) {.async.} =
  await hr.replyOkAs(textContent, contentType, hr.defCharset)

proc replyOkAsText*(hr: HttpRequest, textContent: string, contentCharset: string) {.async.} =
  await hr.replyOkAs(textContent, "text/plain", contentCharset)

proc replyOkAsText*(hr: HttpRequest, textContent: string) {.async.} =
  await hr.replyOkAs(textContent, "text/plain", hr.defCharset)

proc replyOkAsRawJson*(hr: HttpRequest, textContent: string, contentCharset: string) {.async.} =
  await hr.replyOkAs(textContent, "application/json", contentCharset)

proc replyOkAsRawJson*(hr: HttpRequest, textContent: string) {.async.} =
  await hr.replyOkAs(textContent, "application/json", hr.defCharset)

proc replyOkAsJson*(hr: HttpRequest, jsonContent: JsonNode, contentCharset: string) {.async.} =
  await hr.replyOkAs($jsonContent, "application/json", contentCharset)

proc replyOkAsJson*(hr: HttpRequest, jsonContent: JsonNode) {.async.} =
  await hr.replyOkAs($jsonContent, "application/json", hr.defCharset)

proc replyOkAsPrettyJson*(hr: HttpRequest, jsonContent: JsonNode, contentCharset: string) {.async.} =
  await hr.replyOkAs(pretty(jsonContent), "application/json", contentCharset)

proc replyOkAsPrettyJson*(hr: HttpRequest, jsonContent: JsonNode) {.async.} =
  await hr.replyOkAs(pretty(jsonContent), "application/json", hr.defCharset)

proc replyRedirection*(hr: HttpRequest, destination: string) {.async.} =
  await hr.reply(Http301, STRINGS_EMPTY, newHttpHeaders([(LOCATION, destination)]))

proc replyBadRequest*(hr: HttpRequest) {.async.} =
  await hr.reply(Http400, "Bad Request.")

proc replyForbiddenAccess*(hr: HttpRequest) {.async.} =
  await hr.reply(Http403, "Forbidden access.")

proc replyNotFound*(hr: HttpRequest) {.async.} =
  await hr.reply(Http404, "Not found.")

proc replyNotAllowed*(hr: HttpRequest) {.async.} =
  await hr.reply(Http405, "Method not allowed.")

proc replyNotImplemented*(hr: HttpRequest) {.async.} =
  await hr.reply(Http501, "Not implemented.")

proc replyServerError*(hr: HttpRequest) {.async.} =
  await hr.reply(Http505, "Internal server error.")
