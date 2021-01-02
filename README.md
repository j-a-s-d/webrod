# webrod
an easy to use http server for nim

> based on the HttpHost of the net package of my Java Whiz project https://github.com/j-a-s-d/whiz

## EXAMPLE:

```nim
import
  webrod, json, asyncdispatch

var
  host {.threadvar.}: HttpHost

proc handle_simple(hr: HttpRequest) {.async, gcsafe.} =
  await hr.replyOkAsPrettyJson(%* { "message": "Hi!", "took": hr.getCPUTimeSpentAsString() })

proc handle_shutdown(hr: HttpRequest) {.async, gcsafe.} =
  await hr.replyOk("Bye!")
  discard host.stop()

host = newHttpHost()
host.setPort(5000)
host.registerGetHandler("/simple", handle_simple)
host.registerHandler("/shutdown", handle_shutdown)
host.start()
```
*NOTE: compile with the compiler 'threads' flag on*

## HISTORY
* 02-01-20 *[0.1.2]* - improved HttpStand
* 01-01-20 *[0.1.1]* - added HttpStand
* 31-12-20 *[0.1.0]* - first public release
* 17-12-20 *[0.0.1]* - started coding

## TODO
* more features and enhancements
* full unit testing
* markdown documentation
