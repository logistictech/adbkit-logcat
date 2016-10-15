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
      chunk = Buffer.concat([@savedR, chunk])
    last = chunk.length - 1
    while hi <= last
      if chunk[hi] is 0x0d
        count_elems_to_last = last - hi
        if count_elems_to_last is 0
          @savedR = chunk.slice hi
          if hi isnt lo
            this.push chunk.slice lo, hi
            lo = hi + 1
        else if count_elems_to_last is 1
          if chunk[hi + 1] is 0x0d
            @savedR = chunk.slice hi, last + 1
            if hi isnt lo
              this.push chunk.slice lo, hi
            hi = hi + 2
            lo = hi + 1
        else if chunk[hi + 1] is 0x0d and chunk[hi + 2] is 0x0a
          if hi isnt lo
            this.push chunk.slice lo, hi
          lo = hi + 2
          hi = lo
      hi += 1
    unless hi is lo
      this.push chunk.slice lo, hi
    done()
    return

module.exports = Transform
