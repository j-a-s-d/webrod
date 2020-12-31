# webrod by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  strutils

# NOTE: the provided charsets are the same as Java NIO
# see https://docs.oracle.com/javase/7/docs/api/java/nio/charset/StandardCharsets.html

type charset = enum
  UTF_8 = 0 # Eight-bit UCS Transformation Format
  UTF_16LE = 1 # Sixteen-bit UCS Transformation Format, little-endian byte order
  UTF_16BE = 2 # Sixteen-bit UCS Transformation Format, big-endian byte order
  UTF_16 = 3 # Sixteen-bit UCS Transformation Format, byte order identified by an optional byte-order mark
  US_ASCII = 4 # Seven-bit ASCII, a.k.a.
  ISO_8859_1 = 5 # ISO Latin Alphabet No.

const
  charsets: array[charset, string] = [
    "UTF-8",
    "UTF-16LE",
    "UTF-16BE",
    "UTF-16",
    "US-ASCII",
    "ISO-8859-1"
  ]

var
  defaultCharset: charset = UTF_8

proc getDefaultCharset*(): string =
  charsets[defaultCharset]

proc setDefaultCharset*(value: string): bool =
  let idx = charsets.find(toUpperAscii(value))
  if idx != -1:
    for i in low(charsets)..high(charsets):
      if i.int == idx:
        defaultCharset = i
        return true
  return false
