Breakpoint             = require './breakpoint'
levelsWorkspaceManager = require('./levels-workspace-manager').getInstance()
positionUtils          = require('./position-utils').getInstance()

class BreakpointManager
  constructor: ->
    @breakPoints = new Array()
    @areBreakpointsEnabled = true
    @hiddenBreakpointPosition = null

  getAreBreakpointsEnabled: ->
    return @areBreakpointsEnabled

  getBreakpoints: ->
    return @breakPoints

  removeAll: ->
    for bp in @breakPoints
      bp?.destroyMarker()

    @breakPoints = new Array()

  flip: ->
    @areBreakpointsEnabled = !@areBreakpointsEnabled
    for bp in @breakPoints
      if bp?.hasMarker()
        bp.destroyMarker()
        bp.setMarker(levelsWorkspaceManager.addBreakpointMarker(positionUtils.toPoint(bp.getPosition()), @areBreakpointsEnabled))

  toggle: (point) ->
    breakPointPosition = positionUtils.fromPoint(point)
    existingBreakpoint = @getBreakpoint(breakPointPosition)

    if existingBreakpoint?
      @breakPoints = @breakPoints.filter((bp) => bp != existingBreakpoint)
      existingBreakpoint.destroyMarker()
      return false
    else
      marker = levelsWorkspaceManager.addBreakpointMarker(point, @areBreakpointsEnabled)
      @breakPoints.push(new Breakpoint(breakPointPosition, marker))
      return true

  getBreakpoint: (position) ->
    for bp in @breakPoints
      if bp?.getPosition().isOnSameLine(position)
        return bp
    return null

  isBreakpoint: (position) ->
    return @getBreakpoint(position)?

  hideBreakpoint: (position) ->
    if @hiddenBreakpointPosition? && position.isOnSameLine(@hiddenBreakpointPosition)
      console.log "Breakpoint already hidden, can't hide again!"
    else
      breakpoint = @getBreakpoint(position)
      if breakpoint?
        breakpoint.destroyMarker()
        @hiddenBreakpointPosition = breakpoint.getPosition()

  restoreHiddenBreakpoint: ->
    if @hiddenBreakpointPosition?
      existingBreakpoint = @getBreakpoint(@hiddenBreakpointPosition)
      if existingBreakpoint?
        marker = levelsWorkspaceManager.addBreakpointMarker(positionUtils.toPoint(@hiddenBreakpointPosition), @areBreakpointsEnabled)
        existingBreakpoint.setMarker(marker)

    @hiddenBreakpointPosition = null

module.exports =
class BreakpointManagerProvider
  instance = null

  @getInstance: ->
    instance ?= new BreakpointManager()