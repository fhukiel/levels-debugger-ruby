module.exports =
class Breakpoint
  constructor: (position, marker) ->
    @position = position;
    @marker = marker;

  getPosition: ->
    return @position

  setPosition: (position) ->
    @position = position;

  destroyMarker: ->
    if @marker?
      @marker.destroy();
    @marker = null;

  hasMarker: ->
    return @marker?

  setMarker: (marker) ->
    @marker = marker;
