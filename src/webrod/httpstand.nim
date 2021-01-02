# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch, oids

type
  WebRodHttpStand = object
    server: AsyncHttpServer
    listening: bool
    name: string
    port: int
    id: string
    crossOrigin: bool

  HttpStand* = ref WebRodHttpStand

proc newHttpStand*(name: string, port: int): HttpStand =
  result = new WebRodHttpStand
  result.server = newAsyncHttpServer()
  result.listening = false
  result.name = name
  result.port = port
  result.id = $genOid();
  result.crossOrigin = false

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

proc listen*(stand: HttpStand, callback: proc (request: Request): Future[void] {.gcsafe.}) =
  asyncCheck stand.server.serve(Port(stand.port), callback)
  stand.listening = true
  while stand.isListening():
    try:
      poll()
    except:
      stand.listening = false

proc close*(stand: HttpStand): bool =
  stand.listening = false
  stand.server.close()
