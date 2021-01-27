# webrod
an easy to use http server for nim

## CHARACTERISTICS

* no external dependencies (just nim)
* self-documenting api (descriptive long proc names)
* full unit testing (TODO)
* markdown documentation (TODO)
* lot of examples (TODO)
> based on the HttpHost of the net package of my Java Whiz project https://github.com/j-a-s-d/whiz

## EXAMPLE:

```nim
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
```
*NOTE: compile with the compiler 'threads' flag on*

## HISTORY
* 20-01-21 *[0.2.2]*
	- added getProcessedRequestsAmountSinceCreation and getProcessedRequestsAmountSinceCreationAsString to httpstand and httphost
* 18-01-21 *[0.2.1]*
	- added replyOkAsRawJson to httprequest
* 04-01-21 *[0.2.0]*
	- added getElapsedMinutesSinceCreation and getElapsedMinutesSinceCreationAsString to httpstand and httphost
* 03-01-21 *[0.1.3]*
	- added hasError and getErrorMessage to httpstand and httphost
* 02-01-21 *[0.1.2]*
	- improved httpstand
* 01-01-21 *[0.1.1]*
	- added httpstand
* 31-12-20 *[0.1.0]*
	- first public release
* 17-12-20 *[0.0.1]*
	- started coding
