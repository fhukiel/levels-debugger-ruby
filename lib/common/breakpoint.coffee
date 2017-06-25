module.exports =
class Breakpoint
  constructor: (@position, @marker) ->

  getPosition: ->
    return @position

  setPosition: (@position) ->

  destroyMarker: ->
    if @marker?
      @marker.destroy()
    @marker = null

  hasMarker: ->
    return @marker?

  setMarker: (@marker) ->