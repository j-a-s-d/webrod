# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  asynchttpserver, asyncdispatch

type
  WebRodHttpStand = object
    server: AsyncHttpServer
    listening: bool

  HttpStand* = ref WebRodHttpStand

proc newHttpStand*(): HttpStand =
  result = new WebRodHttpStand
  result.server = newAsyncHttpServer()
  result.listening = false

proc isListening*(stand: HttpStand): bool =
  stand.listening

proc listen*(stand: HttpStand, port: int, callback: proc (request: Request): Future[void] {.gcsafe.}) =
  asyncCheck stand.server.serve(Port(port), callback)
  stand.listening = true
  while stand.isListening():
    try:
      poll()
    except:
      stand.listening = false

proc close*(stand: HttpStand): bool =
  stand.listening = false
  stand.server.close()
