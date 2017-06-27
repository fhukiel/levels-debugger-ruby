module.exports =
class Breakpoint
  constructor: (@position, @marker) ->

  getPosition: ->
    return @position

  setPosition: (@position) ->

  destroyMarker: ->
    @marker?.destroy()
    @marker = null

  hasMarker: ->
    return @marker?

  setMarker: (@marker) ->