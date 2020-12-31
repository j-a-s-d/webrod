# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  unittest, asyncdispatch,
  webrod

suite "test webrod":
  # "suite setup: run once before the tests"
  const DEFAULT_PORT: int = 3000
  const HOST_PORT: int = 5000

  webrod.setDefaultPort(DEFAULT_PORT)

  var host {.threadvar.}: HttpHost

  proc handle_ok(hr: HttpRequest) {.async, gcsafe.} =
    await hr.replyOk("ok")
  
  proc handle_autodrop(hr: HttpRequest) {.async, gcsafe.} =
    await hr.replyOk("ok")
    host.unregisterHandler(handle_autodrop)

  proc handle_shutdown(hr: HttpRequest) {.async, gcsafe.} =
    if host.stop(): await hr.replyOk("ok")
  
  proc handle_jsonecho(hr: HttpRequest) {.async, gcsafe.} = # test
    try: await hr.replyOkAsPrettyJson(hr.getRequestBodyAsJson()) except: await hr.replyBadRequest()
  # curl -XPOST -d{\"hey\"\:1} http://127.0.0.1:5000/jsonecho

  setup: # "run before each test"
    host = newHttpHost()
  
  teardown: # "run after each test"
    host = nil
  
  test "port is " & $DEFAULT_PORT:
    require(host.getPort() == DEFAULT_PORT)
  
  test "register handlers":
    host.registerGetHandler("/ok", handle_ok)
    check(host.hasHandlerForRoute("/ok"))
    host.registerPostHandler("/jsonecho", handle_jsonecho)
    check(host.hasHandlerForRoute("/jsonecho"))
    host.registerHandler("/autodrop", handle_autodrop)
    check(host.hasHandlerForRoute("/autodrop"))
    host.registerHandler("/shutdown", handle_shutdown)
    check(host.hasHandlerForRoute("/shutdown"))
  
  test "static files serving is disabled by default":
    check(not host.isStaticFileServingEnabled())
  
  test "is not listening by default":
    check(not host.isListening())
  
  test "enable static files serving":
    host.enableStaticFileServing("/", "client")
    check(host.isStaticFileServingEnabled())
  
  test "toggle cross origin allowance":
    require(host.getCrossOriginAllowance() == false)
    host.setCrossOriginAllowance(true)
    require(host.getCrossOriginAllowance() == true)
    host.setCrossOriginAllowance(false)
    require(host.getCrossOriginAllowance() == false)
  
  test "change name to TEST":
    host.setName("TEST")
    require(host.getName() == "TEST")
  
  test "change port to " & $HOST_PORT:
    host.setPort(HOST_PORT)
    require(host.getPort() == HOST_PORT)
  
  test "charset is UTF-8 by default":
    require(webrod.getDefaultCharset() == "UTF-8")
  
  test "change charset to UTF-16 and restore to UTF-8":
    require(webrod.setDefaultCharset("utf-16"))
    require(webrod.getDefaultCharset() == "UTF-16")
    require(webrod.setDefaultCharset("utf-8"))
    require(webrod.getDefaultCharset() == "UTF-8")
  
  test "unregister handlers":
    host.unregisterHandler("/ok")
    check(not host.hasHandlerForRoute("/ok"))
    host.unregisterHandler(handle_jsonecho)
    check(not host.hasHandlerForRoute("/jsonecho"))
    host.unregisterHandler("/autodrop")
    check(not host.hasHandlerForRoute("/autodrop"))
    host.unregisterHandler(handle_shutdown)
    check(not host.hasHandlerForRoute("/shutdown"))
  # "suite teardown: run once after the tests"
