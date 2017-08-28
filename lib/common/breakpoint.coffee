module.exports =
class Breakpoint
  constructor: (@position, @marker) ->

  getPosition: ->
    return @position

  destroyMarker: ->
    @marker?.destroy()
    @marker = null
    return

  hasMarker: ->
    return @marker?

  setMarker: (@marker) ->