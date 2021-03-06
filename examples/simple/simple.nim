# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)
#   simple example
# compile:
#   nim c --threads:on simple.nim

import
  webrod, json, asyncdispatch

var
  host {.threadvar.}: HttpHost

proc handle_simple(hr: HttpRequest) {.async, gcsafe.} =
  await hr.replyOkAsPrettyJson(%* {
    "request": hr.getStand().getProcessedRequestsAmountSinceCreationAsString(),
    "message": "Hi!",
    "took": hr.getCPUTimeSpentAsString(),
    "online": hr.getStand().getElapsedMinutesSinceCreationAsString()
  })

proc handle_shutdown(hr: HttpRequest) {.async, gcsafe.} =
  await hr.replyOk("Bye!")
  discard host.stop()

host = newHttpHost()
host.setPort(5000)
host.registerGetHandler("/simple", handle_simple)
host.registerHandler("/shutdown", handle_shutdown)
host.start()
if host.hasError():
  echo host.getErrorMessage()

