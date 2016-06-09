module.exports =
class Position
  constructor: (line, column) ->
    @line = line;
    @column = column;

  getLine: ->
    return @line

  getColumn: ->
    return @column

  isOnSameLine: (other) ->
    if other?
      return other.getLine() == @getLine();
    return false;
