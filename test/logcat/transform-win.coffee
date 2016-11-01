Stream = require 'stream'
Sinon = require 'sinon'
Chai = require 'chai'
Chai.use require 'sinon-chai'
{expect} = Chai

Transform = require '../../src/logcat/transform-win'
MockDuplex = require '../mock/duplex'

describe 'Transform', ->

  it "should implement stream.Transform", (done) ->
    expect(new Transform).to.be.an.instanceOf Stream.Transform
    done()

  it "should not modify data that does not have 0x0d 0x0d 0x0a in it", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.toString()).to.equal 'foo'
      done()
    duplex.pipe transform
    duplex.causeRead 'foo'
    duplex.causeEnd()

  it "should not remove 0x0d if not followed by 0x0d or 0x0a", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.length).to.equal 2
      expect(data[0]).to.equal 0x0d
      expect(data[1]).to.equal 0x05
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x0d, 0x05]
    duplex.causeEnd()

  it "should not remove 0x0d if followed by 0x0a", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.length).to.equal 2
      expect(data[0]).to.equal 0x0d
      expect(data[1]).to.equal 0x0a
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x0d, 0x0a]
    duplex.causeEnd()

  it "should not remove 0x0d 0x0d if not followed by 0x0a", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.length).to.equal 3
      expect(data[0]).to.equal 0x0d
      expect(data[1]).to.equal 0x0d
      expect(data[2]).to.equal 0x05
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x0d, 0x0d, 0x05]
    duplex.causeEnd()

  it "should remove 0x0d 0x0d if followed by 0x0a", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.length).to.equal 2
      expect(data[0]).to.equal 0x0a
      expect(data[1]).to.equal 0x97
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x0d, 0x0d, 0x0a, 0x97]
    duplex.causeEnd()

  it "should not push 0x0d if last in stream", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.length).to.equal 1
      expect(data[0]).to.equal 0x62
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d]

  it "should not push 0x0d 0x0d if last in stream", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    transform.on 'data', (data) ->
      expect(data.length).to.equal 1
      expect(data[0]).to.equal 0x62
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d, 0x0d]

  it "should push saved 0x0d if next chunk does not start with 0x0d or 0x0a",
  (done) ->
    duplex = new MockDuplex
    transform = new Transform
    buffer = new Buffer ''
    transform.on 'data', (data) ->
      buffer = Buffer.concat [buffer, data]
    transform.on 'end', ->
      expect(buffer).to.have.length 3
      expect(buffer[0]).to.equal 0x62
      expect(buffer[1]).to.equal 0x0d
      expect(buffer[2]).to.equal 0x37
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d]
    duplex.causeRead new Buffer [0x37]
    duplex.causeEnd()

  it "should push saved 0x0d if next chunk starts with 0x0a", (done) ->
    duplex = new MockDuplex
    transform = new Transform
    buffer = new Buffer ''
    transform.on 'data', (data) ->
      buffer = Buffer.concat [buffer, data]
    transform.on 'end', ->
      expect(buffer).to.have.length 3
      expect(buffer[0]).to.equal 0x62
      expect(buffer[1]).to.equal 0x0d
      expect(buffer[2]).to.equal 0x0a
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d]
    duplex.causeRead new Buffer [0x0a]
    duplex.causeEnd()

  it "should push saved 0x0d 0x0d if next chunk does not start with 0x0a",
  (done) ->
    duplex = new MockDuplex
    transform = new Transform
    buffer = new Buffer ''
    transform.on 'data', (data) ->
      buffer = Buffer.concat [buffer, data]
    transform.on 'end', ->
      expect(buffer).to.have.length 4
      expect(buffer[0]).to.equal 0x62
      expect(buffer[1]).to.equal 0x0d
      expect(buffer[2]).to.equal 0x0d
      expect(buffer[3]).to.equal 0x37
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d, 0x0d]
    duplex.causeRead new Buffer [0x37]
    duplex.causeEnd()

  it "should remove 0x0d 0x0d in case of chunk border '0x0d | 0x0d 0x0a'",
  (done) ->
    duplex = new MockDuplex
    transform = new Transform
    buffer = new Buffer ''
    transform.on 'data', (data) ->
      buffer = Buffer.concat [buffer, data]
    transform.on 'end', ->
      expect(buffer).to.have.length 2
      expect(buffer[0]).to.equal 0x62
      expect(buffer[1]).to.equal 0x0a
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d]
    duplex.causeRead new Buffer [0x0d, 0x0a]
    duplex.causeEnd()

  it "should remove 0x0d 0x0d in case of chunk border '0x0d 0x0d | 0x0a'",
  (done) ->
    duplex = new MockDuplex
    transform = new Transform
    buffer = new Buffer ''
    transform.on 'data', (data) ->
      buffer = Buffer.concat [buffer, data]
    transform.on 'end', ->
      expect(buffer).to.have.length 2
      expect(buffer[0]).to.equal 0x62
      expect(buffer[1]).to.equal 0x0a
      done()
    duplex.pipe transform
    duplex.causeRead new Buffer [0x62, 0x0d, 0x0d]
    duplex.causeRead new Buffer [0x0a]
    duplex.causeEnd()

  it "should clear saved 0x0d after processing of next chunk",
    (done) ->
      duplex = new MockDuplex
      transform = new Transform
      buffer = new Buffer ''
      transform.on 'data', (data) ->
        buffer = Buffer.concat [buffer, data]
      transform.on 'end', ->
        expect(buffer).to.have.length 4
        expect(buffer[0]).to.equal 0x62
        expect(buffer[1]).to.equal 0x0d
        expect(buffer[2]).to.equal 0x37
        expect(buffer[3]).to.equal 0x42
        done()
      duplex.pipe transform
      duplex.causeRead new Buffer [0x62, 0x0d]
      duplex.causeRead new Buffer [0x37]
      duplex.causeRead new Buffer [0x42]
      duplex.causeEnd()

  it "should clear saved 0x0d 0x0d after processing of next chunk",
    (done) ->
      duplex = new MockDuplex
      transform = new Transform
      buffer = new Buffer ''
      transform.on 'data', (data) ->
        buffer = Buffer.concat [buffer, data]
      transform.on 'end', ->
        expect(buffer).to.have.length 5
        expect(buffer[0]).to.equal 0x62
        expect(buffer[1]).to.equal 0x0d
        expect(buffer[2]).to.equal 0x0d
        expect(buffer[3]).to.equal 0x37
        expect(buffer[4]).to.equal 0x42
        done()
      duplex.pipe transform
      duplex.causeRead new Buffer [0x62, 0x0d, 0x0d]
      duplex.causeRead new Buffer [0x37]
      duplex.causeRead new Buffer [0x42]
      duplex.causeEnd()
