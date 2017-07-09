class LevelsWorkspaceManager
  attachWorkspace: (@levelsWorkspace) ->

  getWorkspace: ->
    return @levelsWorkspace

  getActiveTerminal: ->
    return @levelsWorkspace?.getActiveTerminal()

  getActiveLevelCodeEditor: ->
    return @levelsWorkspace?.getActiveLevelCodeEditor()

  getActiveTextEditor: ->
    return @getActiveLevelCodeEditor()?.getTextEditor()

  getActiveLevel: ->
    return @levelsWorkspace?.getActiveLevel()

  isActiveLevelDebuggable: ->
    isDebuggable = @getActiveLevel()?.getOption 'debuggable'

    return isDebuggable? && isDebuggable

  getActiveTextEditorPosition: ->
    return @getActiveTextEditor()?.getCursorBufferPosition()

  addBreakpointMarker: (atPoint, isEnabled) ->
    textEditor = @getActiveTextEditor()
    marker = textEditor?.markBufferPosition atPoint, invalidate: 'inside'
    className = if isEnabled then 'annotation annotation-breakpoint' else 'annotation annotation-breakpoint-disabled'
    textEditor?.decorateMarker marker, {type: 'line-number', class: className}

    return marker

  addPositionMarker: (atPosition) ->
    textEditor = @getActiveTextEditor()
    marker = textEditor?.markBufferPosition [atPosition.getLine() - 1, atPosition.getColumn()], invalidate: 'inside'
    textEditor?.decorateMarker marker, {type: 'line-number', class: 'annotation annotation-position'}

    return marker

module.exports =
class LevelsWorkspaceManagerProvider
  instance = null

  @getInstance: ->
    instance ?= new LevelsWorkspaceManager