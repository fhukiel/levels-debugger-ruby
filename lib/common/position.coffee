module.exports =
class Position
  constructor: (@line, @column) ->

  getLine: ->
    return @line

  getColumn: ->
    return @column

  isOnSameLine: (other) ->
    if other
      return other.getLine() == @line
    return false