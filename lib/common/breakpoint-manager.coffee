{Point}                   = require 'atom'
Breakpoint                = require('./breakpoint');
positionUtils             = require('./position-utils').getInstance()
levelsWorkspaceManager    = require('./levels-workspace-manager').getInstance()

class BreakpointManager
  constructor: (serializedState) ->
    @breakPoints = new Array();
    @areBreakpointsEnabled = true;
    @hiddenBreakpointPosition = null;

  getAreBreakpointsEnabled: ->
    return @areBreakpointsEnabled;

  getBreakpoints: ->
    return @breakPoints;

  removeAll: ->
    console.log "Remove all breakpoints called."
    for bp in @breakPoints
      bp?.destroyMarker();
    @breakPoints = new Array();

  flip: ->
    console.log "Enable / disable all breakpoints called, enabled has value #{@areBreakpointsEnabled}."
    @areBreakpointsEnabled = !@areBreakpointsEnabled
    for bp in @breakPoints
      if bp?.hasMarker()
        bp.destroyMarker();
        bp.setMarker(levelsWorkspaceManager.addBreakpointMarker(positionUtils.toPoint(bp.getPosition()), @areBreakpointsEnabled));

  # Returns true if breakpoint added at position, false if removed at position
  toggle: (point) ->
    console.log "Toggle breakpoint called."
    breakPointPosition = positionUtils.fromPoint(point)
    existingBreakpoint = @getBreakpoint(breakPointPosition)
    if existingBreakpoint isnt null
      console.log "Removing breakpoint."
      @breakPoints = @breakPoints.filter (bp) -> bp isnt existingBreakpoint
      existingBreakpoint.destroyMarker();
      return false;
    else
      console.log "Adding breakpoint."
      marker = levelsWorkspaceManager.addBreakpointMarker(point, @areBreakpointsEnabled);
      @breakPoints.push(new Breakpoint(breakPointPosition, marker))
      return true;

  getBreakpoint: (position) ->
    for bp in @breakPoints
      if bp?.getPosition().isOnSameLine(position)
        return bp;
    return null;

  isBreakpoint: (position) ->
    return @getBreakpoint(position)?

  hideBreakpoint: (position) ->
    if @hiddenBreakpointPosition? and position.isOnSameLine(@hiddenBreakpointPosition)
      console.log "Breakpoint already hidden, can't hide again"
    else
      breakpoint = @getBreakpoint(position)
      if breakpoint?
        console.log "Hit a breakpoint, hiding its marker."
        breakpoint.destroyMarker();
        @hiddenBreakpointPosition = breakpoint.getPosition();

  restoreHiddenBreakpoint: () ->
    if @hiddenBreakpointPosition?
      console.log "A previous breakpoint marker will be restored."
      existingBreakpoint = @getBreakpoint(@hiddenBreakpointPosition)
      if existingBreakpoint?
        console.log "Still a breakpoint"
        marker = levelsWorkspaceManager.addBreakpointMarker(positionUtils.toPoint(@hiddenBreakpointPosition), @areBreakpointsEnabled);
        existingBreakpoint.setMarker(marker)
    @hiddenBreakpointPosition = null;

module.exports =
class BreakpointManagerProvider
  instance = null
  @getInstance: ->
    instance ?= new BreakpointManager
