module.exports =
class VariableTableEntry
  constructor: (@name, @value, @address) ->
    @changed = false
    @changedExpiresAt = 0

  getName: ->
    return @name

  getValue: ->
    return @value

  getAddress: ->
    return @address

  isChanged: ->
    return @changed && !@isChangedExpired()

  setChanged: (@changed) ->
    if @changed
      @changedExpiresAt = Date.now() + 20
    return

  getChangedExpiresAt: ->
    return @changedExpiresAt

  isChangedExpired: ->
    return @changedExpiresAt < Date.now()

  setChangedExpiresAt: (@changedExpiresAt) ->

  equals: (other) ->
    if !other?
      return false
    if other.getName() != @name
      return false
    if other.getValue() != @value
      return false
    if other.getAddress() != @address
      return false
    return true