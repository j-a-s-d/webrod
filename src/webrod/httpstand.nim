# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, oids, strutils, times

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

  HttpStand* = ref WebRodHttpStand

proc newHttpStand*(name: string, port: int): HttpStand =
  result = new WebRodHttpStand
  result.server = newAsyncHttpServer()
  result.listening = false
  result.error = false
  result.errorMsg = ""
  result.name = name
  result.port = port
  result.id = $genOid();
  result.crossOrigin = false
  result.created = epochTime()

proc getElapsedMinutesSinceCreation*(stand: HttpStand): float =
  (epochTime() - stand.created) / 60

proc getElapsedMinutesSinceCreationAsString*(stand: HttpStand, appendix: string = "m"): string =
  getElapsedMinutesSinceCreation(stand).formatFloat(format = ffDecimal, precision = 0).replace(".", appendix)

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
    stand.errorMsg = ""
    stand.listening = true
    asyncCheck stand.server.serve(Port(stand.port), callback)
    while stand.isListening():
      poll()
  except:
    if stand.listening:
      stand.error = true
      stand.errorMsg = getCurrentExceptionMsg().split("\n")[0]
    stand.listening = false

proc close*(stand: HttpStand): bool =
  stand.listening = false
  stand.server.close()
