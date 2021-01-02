# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, uri, cookies, times, json, strtabs, strutils,
  httpstand, standardcharsets

const DATE_FORMATTING_VALUE: string = "ddd, yyyy-MM-dd hh:mm:ss 'GMT'"
const NO_CACHE_CONTROL: string = "no-cache, no-store, max-age=0"

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

proc getCPUTimeSpentAsString*(hr: HttpRequest, decimals: int = 3, appendix: string = "s"): string =
  getCPUTimeSpent(hr).formatFloat(format = ffDecimal, precision = decimals) & appendix

proc getRequestElapsedTime*(hr: HttpRequest): float =
  epochTime() - hr.created

proc getRequestElapsedTimeAsString*(hr: HttpRequest, decimals: int = 3, appendix: string = "s"): string =
  getRequestElapsedTime(hr).formatFloat(format = ffDecimal, precision = decimals) & appendix

proc getRequestBodyAsJson*(hr: HttpRequest): JsonNode =
  try:
    parseJson(hr.req.body)
  except:
    nil

proc getRequestQueryStringAsStringTable*(hr: HttpRequest): StringTableRef =
  result = newStringTable()
  let qsp = hr.req.url.query.split("&")
  for i in 0..high(qsp):
    let tmp = qsp[i].split("=")
    if tmp.len == 2:
      result[tmp[0]] = tmp[1]

proc getRequestCookiesAsStringTable*(hr: HttpRequest): StringTableRef =
  if hr.req.headers.hasKey("Cookie"):
    parseCookies(hr.req.headers["Cookie"])
  elif hr.req.headers.hasKey("Cookie2"): # NOTE: see RFC 2965
    parseCookies(hr.req.headers["Cookie2"])
  else:
    newStringTable()

proc clearResponseCookies*(hr: HttpRequest) =
  hr.cookies.clear(modeCaseSensitive)

proc addResponseCookies*(hr: HttpRequest, cookieTable: StringTableRef) =
  for k, v in cookieTable:
    hr.cookies[k] = encodeUrl(v, true)

proc reply*(hr: HttpRequest, httpCode: HttpCode, textContent: string, httpHeaders: HttpHeaders = newHttpHeaders()) {.async.} =
  httpHeaders["Date"] = now().utc.format(DATE_FORMATTING_VALUE)
  httpHeaders["Server"] = hr.stand.getName()
  if not httpHeaders.hasKey("Cache-Control"):
    httpHeaders["Cache-Control"] = NO_CACHE_CONTROL
  if hr.stand.getCrossOriginAllowance():
    httpHeaders["Access-Control-Allow-Origin"] = "*"
  if len(hr.cookies) > 0:
    var c: seq[string] = @[]
    for k, v in hr.cookies:
      c.add(k & "=" & v & ";")
    httpHeaders["Set-Cookie"] = c
  await hr.req.respond(httpCode, textContent, httpHeaders)

proc replyOk*(hr: HttpRequest, textContent: string, httpHeaders: HttpHeaders = newHttpHeaders()) {.async.} =
  await hr.reply(Http200, textContent, httpHeaders)

proc replyOkAs*(hr: HttpRequest, textContent: string, contentType: string, contentCharset: string) {.async.} =
  await hr.replyOk(textContent, newHttpHeaders([("Content-Type", contentType & "; charset=" & contentCharset)]))

proc replyOkAs*(hr: HttpRequest, textContent: string, contentType: string) {.async.} =
  await hr.replyOkAs(textContent, contentType, hr.defCharset)

proc replyOkAsText*(hr: HttpRequest, textContent: string, contentCharset: string) {.async.} =
  await hr.replyOkAs(textContent, "text/plain", contentCharset)

proc replyOkAsText*(hr: HttpRequest, textContent: string) {.async.} =
  await hr.replyOkAs(textContent, "text/plain", hr.defCharset)

proc replyOkAsJson*(hr: HttpRequest, jsonContent: JsonNode, contentCharset: string) {.async.} =
  await hr.replyOkAs($jsonContent, "application/json", contentCharset)

proc replyOkAsJson*(hr: HttpRequest, jsonContent: JsonNode) {.async.} =
  await hr.replyOkAs($jsonContent, "application/json", hr.defCharset)

proc replyOkAsPrettyJson*(hr: HttpRequest, jsonContent: JsonNode, contentCharset: string) {.async.} =
  await hr.replyOkAs(pretty(jsonContent), "application/json", contentCharset)

proc replyOkAsPrettyJson*(hr: HttpRequest, jsonContent: JsonNode) {.async.} =
  await hr.replyOkAs(pretty(jsonContent), "application/json", hr.defCharset)

proc replyRedirection*(hr: HttpRequest, destination: string) {.async.} =
  await hr.reply(Http301, "", newHttpHeaders([("Location", destination)]))

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
