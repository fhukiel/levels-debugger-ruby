{Point}  = require('atom')
Position = require('./position')

class PositionUtils
  fromPoint: (point) ->
    return new Position(point.row + 1, point.column)

  toPoint: (position) ->
    return new Point(position.getLine() - 1, position.getColumn())

module.exports =
class PositionUtilsProvider
  instance = null

  @getInstance: ->
    instance ?= new PositionUtils()