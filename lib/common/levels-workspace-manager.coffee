class LevelsWorkspaceManager
  constructor: (serializedState) ->

  serialize: ->

  destroy: ->

  attachWorkspace: (workspace) ->
    @levelsWorkspace = workspace;

  getWorkspace: ->
    return @levelsWorkspace;

  getActiveTerminal: ->
    return @levelsWorkspace?.getActiveTerminal();

  getActiveLevelCodeEditor: ->
    return @levelsWorkspace?.getActiveLevelCodeEditor();

  getActiveTextEditor: ->
    editor = @getActiveLevelCodeEditor()
    return editor?.getTextEditor();

  getActiveLevel: ->
    return @levelsWorkspace?.getActiveLevel();

  isActiveLevelDebuggable: ->
    isDebuggable = @getActiveLevel()?.getOption('debuggable');
    if isDebuggable? and isDebuggable
      return true
    return false;

  getActiveTextEditorPosition: ->
    return @getActiveTextEditor()?.getCursorBufferPosition();

  addBreakpointMarker: (atPoint, isEnabled)->
    textEditor = @getActiveTextEditor()
    marker = textEditor?.markBufferPosition atPoint, invalidate: 'inside'
    className = if isEnabled then "annotation annotation-breakpoint" else "annotation annotation-breakpoint-disabled"
    textEditor?.decorateMarker marker,
      type: 'line-number'
      class: className
    return marker;

  addPositionMarker: (atPosition) ->
    textEditor = @getActiveTextEditor()
    positionMarker = textEditor?.markBufferPosition [atPosition.getLine()-1, atPosition.getColumn()],
        invalidate: 'inside'
    textEditor?.decorateMarker positionMarker,
        type: 'line-number'
        class: "annotation annotation-position"
    return positionMarker;

module.exports =
class LevelsWorkspaceManagerProvider
  instance = null
  @getInstance: ->
    instance ?= new LevelsWorkspaceManager
