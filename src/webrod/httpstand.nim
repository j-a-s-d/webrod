# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, oids, strutils, times,
  xam

type
  WebRodHttpStand = object
    server: AsyncHttpServer
    listening: bool
    error: bool
    errorMsg: string
    name: string
    port: int
    id: string
    crossOrigin: bool
    created: float
    processedRequests: int

  HttpStand* = ref WebRodHttpStand

proc newHttpStand*(name: string, port: int): HttpStand =
  result = new WebRodHttpStand
  result.server = newAsyncHttpServer()
  result.listening = false
  result.error = false
  result.errorMsg = STRINGS_EMPTY
  result.name = name
  result.port = port
  result.id = $genOid();
  result.crossOrigin = false
  result.created = epochTime()
  result.processedRequests = 0

proc getProcessedRequestsAmountSinceCreation*(stand: HttpStand): int =
  stand.processedRequests

proc getProcessedRequestsAmountSinceCreationAsString*(stand: HttpStand): string =
  $getProcessedRequestsAmountSinceCreation(stand)

proc getElapsedMinutesSinceCreation*(stand: HttpStand): float =
  (epochTime() - stand.created) / 60

proc getElapsedMinutesSinceCreationAsString*(stand: HttpStand, appendix: string = STRINGS_LOWERCASE_M): string =
  getElapsedMinutesSinceCreation(stand).formatFloat(format = ffDecimal, precision = 0).replace(STRINGS_PERIOD, appendix)

proc getId*(stand: HttpStand): string =
  stand.id

proc getPort*(stand: HttpStand): int =
  stand.port

proc setPort*(stand: HttpStand, value: int) =
  stand.port = value

proc getName*(stand: HttpStand): string =
  stand.name

proc setName*(stand: HttpStand, value: string) =
  stand.name = value

proc getCrossOriginAllowance*(stand: HttpStand): bool =
  stand.crossOrigin

proc setCrossOriginAllowance*(stand: HttpStand, value: bool) =
  stand.crossOrigin = value

proc isListening*(stand: HttpStand): bool =
  stand.listening

proc hasError*(stand: HttpStand): bool =
  stand.error
  
proc getErrorMessage*(stand: HttpStand): string =
  stand.errorMsg

proc listen*(stand: HttpStand, callback: proc (request: Request): Future[void] {.gcsafe.}) =
  try:
    stand.error = false
    stand.errorMsg = STRINGS_EMPTY
    stand.listening = true
    asyncCheck stand.server.serve(Port(stand.port), proc (request: Request): Future[void] {.gcsafe.} =
        inc(stand.processedRequests)
        callback(request)
    )
    while stand.isListening():
      poll()
  except:
    if stand.listening:
      stand.error = true
      stand.errorMsg = getCurrentExceptionMsg().split(STRINGS_LF)[0]
    stand.listening = false

proc close*(stand: HttpStand): bool =
  stand.listening = false
  stand.server.close()
