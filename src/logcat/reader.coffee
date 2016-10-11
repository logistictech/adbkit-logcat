{EventEmitter} = require 'events'

Parser = require './parser'

eol = require('os').EOL
transformType = if eol is '\r\n' then 'win' else 'posix'
Transform = require "./transform-#{transformType}"

Priority = require './priority'

class Reader extends EventEmitter
  @ANY = '*'

  constructor: (@options = {}) ->
    @options.format ||= 'binary'
    @options.fixLineFeeds = true unless @options.fixLineFeeds?
    @filters =
      all: -1
      tags: {}
    @parser = Parser.get @options.format
    @stream = null

  exclude: (tag) ->
    return this.excludeAll() if tag is Reader.ANY
    @filters.tags[tag] = Priority.SILENT
    return this

  excludeAll: ->
    @filters.all = Priority.SILENT
    return this

  include: (tag, priority = Priority.DEBUG) ->
    return this.includeAll priority if tag is Reader.ANY
    @filters.tags[tag] = this._priority priority
    return this

  includeAll: (priority = Priority.DEBUG) ->
    @filters.all = this._priority priority
    return this

  resetFilters: ->
    @filters.all = -1
    @filters.tags = {}
    return this

  _hook: ->
    if @options.fixLineFeeds
      transform = @stream.pipe new Transform
      transform.on 'data', (data) =>
        @parser.parse data
    else
      @stream.on 'data', (data) =>
        @parser.parse data
    @stream.on 'error', (err) =>
      this.emit 'error', err
    @stream.on 'end', =>
      this.emit 'end'
    @stream.on 'finish', =>
      this.emit 'finish'
    @parser.on 'entry', (entry) =>
      this.emit 'entry', entry if this._filter entry
    @parser.on 'error', (err) =>
      this.emit 'error', err
    return

  _filter: (entry) ->
    priority = @filters.tags[entry.tag]
    unless priority >= 0
      priority = @filters.all
    return entry.priority >= priority

  _priority: (priority) ->
    if typeof priority is 'number'
      return priority
    Priority.fromName priority

  connect: (@stream) ->
    this._hook()
    return this

  end: ->
    @stream.end()
    return this

module.exports = Reader
