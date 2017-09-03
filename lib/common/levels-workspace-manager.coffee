{Emitter} = require 'atom'

class LevelsWorkspaceManager
  constructor: ->
    @emitter = new Emitter

  destroy: ->
    @emitter.dispose()
    return

  attachWorkspace: (@levelsWorkspace) ->
    @emitter.emit 'workspace-attached', @levelsWorkspace
    return

  onWorkspaceAttached: (callback) ->
    @emitter.on 'workspace-attached', callback

  getWorkspace: ->
    return @levelsWorkspace

  getActiveTerminal: ->
    return @levelsWorkspace?.getActiveTerminal()

  getActiveLevelCodeEditor: ->
    return @levelsWorkspace?.getActiveLevelCodeEditor()

  getActiveTextEditor: ->
    return @getActiveLevelCodeEditor()?.getTextEditor()

  getActiveLanguage: ->
    return @levelsWorkspace?.getActiveLanguage()

  isActiveLanguageRuby: ->
    return @getActiveLanguage()?.getName() == 'Ruby'

  getActiveLevel: ->
    return @levelsWorkspace?.getActiveLevel()

  isActiveLevelDebuggable: ->
    isDebuggable = @getActiveLevel()?.getOption 'debuggable'
    return isDebuggable? && isDebuggable

  getActiveTextEditorCursorPositions: ->
    return @getActiveTextEditor()?.getCursorBufferPositions()

  addBreakpointMarker: (point, enabled) ->
    textEditor = @getActiveTextEditor()
    marker = textEditor?.markBufferPosition point, invalidate: 'inside'
    className = if enabled then 'annotation annotation-breakpoint' else 'annotation annotation-breakpoint-disabled'
    textEditor?.decorateMarker marker, {type: 'line-number', class: className}

    return marker

  addPositionMarker: (point) ->
    textEditor = @getActiveTextEditor()
    marker = textEditor?.markBufferPosition point, invalidate: 'inside'
    textEditor?.decorateMarker marker, {type: 'line-number', class: 'annotation annotation-position'}

    return marker

module.exports =
class LevelsWorkspaceManagerProvider
  instance = null

  @getInstance: ->
    instance ?= new LevelsWorkspaceManager