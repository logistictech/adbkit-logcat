Stream = require 'stream'

class Transform extends Stream.Transform
  constructor: (options) ->
    @savedR = null
    super options

  # Sadly, the ADB shell is not very smart. On Windows, it converts every
  # 0x0a ('\n') it can find to 0x0d 0x0d 0x0a ('\r\r\n'). This also applies to
  # binary content. It does do this for all line feeds, so a simple transform
  # works fine.
  _transform: (chunk, encoding, done) ->
    lo = 0
    hi = 0
    if @savedR
      chunk = Buffer.concat [@savedR, chunk]
      @savedR = null
    last = chunk.length - 1
    while hi <= last
      if chunk[hi] is 0x0d
        if hi is last or (hi + 1 is last and chunk[last] is 0x0d)
          @savedR = chunk.slice hi
          break
        else if chunk[hi + 1] is 0x0d and chunk[hi + 2] is 0x0a
          unless hi is lo
            this.push chunk.slice lo, hi
          lo = hi + 2
          hi = lo
      hi += 1
    unless hi is lo
      this.push chunk.slice lo, hi
    done()
    return

module.exports = Transform
