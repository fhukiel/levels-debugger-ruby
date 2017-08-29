Breakpoint             = require './breakpoint'
levelsWorkspaceManager = require('./levels-workspace-manager').getInstance()
PositionUtils          = require './position-utils'

class BreakpointManager
  constructor: ->
    @breakPoints = []
    @areBreakpointsEnabled = true
    @hiddenBreakpointPosition = null

  getAreBreakpointsEnabled: ->
    return @areBreakpointsEnabled

  getBreakpoints: ->
    return @breakPoints

  removeAll: ->
    for bp in @breakPoints
      bp.destroyMarker()

    @breakPoints = []
    return

  flip: ->
    @areBreakpointsEnabled = !@areBreakpointsEnabled
    for bp in @breakPoints
      if bp.hasMarker()
        bp.destroyMarker()
        bp.setMarker levelsWorkspaceManager.addBreakpointMarker PositionUtils.toPoint(bp.getPosition()), @areBreakpointsEnabled
    return

  toggle: (point) ->
    breakPointPosition = PositionUtils.fromPoint point
    existingBreakpoint = @getBreakpoint breakPointPosition

    if existingBreakpoint?
      @breakPoints = @breakPoints.filter (bp) -> bp != existingBreakpoint
      existingBreakpoint.destroyMarker()
      return false
    else
      marker = levelsWorkspaceManager.addBreakpointMarker point, @areBreakpointsEnabled
      @breakPoints.push new Breakpoint breakPointPosition, marker
      return true

  getBreakpoint: (position) ->
    for bp in @breakPoints
      if bp.getPosition().isOnSameLine position
        return bp
    return null

  hideBreakpoint: (position) ->
    if @hiddenBreakpointPosition? && position.isOnSameLine(@hiddenBreakpointPosition)
      console.log "Breakpoint already hidden, can't hide again!"
    else
      breakpoint = @getBreakpoint position
      if breakpoint?
        breakpoint.destroyMarker()
        @hiddenBreakpointPosition = breakpoint.getPosition()
    return

  restoreHiddenBreakpoint: ->
    if @hiddenBreakpointPosition?
      existingBreakpoint = @getBreakpoint @hiddenBreakpointPosition
      if existingBreakpoint?
        marker = levelsWorkspaceManager.addBreakpointMarker PositionUtils.toPoint(@hiddenBreakpointPosition), @areBreakpointsEnabled
        existingBreakpoint.setMarker marker

    @hiddenBreakpointPosition = null
    return

module.exports =
class BreakpointManagerProvider
  instance = null

  @getInstance: ->
    instance ?= new BreakpointManager