# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  xam,
  httprequest, httprequest_callbacks

proc makeReqBodyNonEmptyStringValidator*(): ReqValidator =
  return proc (hr: HttpRequest): bool {.gcsafe.} =
    hasContent(hr.req.body)

proc makeReqBodyValidJsonValidator*(): ReqValidator =
  return proc (hr: HttpRequest): bool {.gcsafe.} =
    assigned(hr.getRequestBodyAsJson())

proc makeReqBodyModelledJsonValidator*(jm: JsonModel): ReqValidator =
  return proc (hr: HttpRequest): bool {.gcsafe.} =
    jm.validate(hr.getRequestBodyAsJson()).success
