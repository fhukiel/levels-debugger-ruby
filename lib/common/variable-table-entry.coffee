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

  getChangedExpiresAt: ->
    return @changedExpiresAt

  isChangedExpired: ->
    return @changedExpiresAt < Date.now()

  setChangedExpiresAt: (time) ->
    @changedExpiresAt = time

  equals: (other) ->
    if !other?
      return false
    if other.getName().valueOf() != @name.valueOf()
      return false
    if other.getValue().valueOf() != @value.valueOf()
      return false
    if other.getAddress().valueOf() != @address.valueOf()
      return false
    return true