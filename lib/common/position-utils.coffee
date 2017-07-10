{Point}  = require 'atom'
Position = require './position'

module.exports =
class PositionUtils
  @fromPoint: (point) ->
    return new Position point.row + 1, point.column

  @toPoint: (position) ->
    return new Point position.getLine() - 1, position.getColumn()