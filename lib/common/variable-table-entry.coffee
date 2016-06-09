module.exports =
class VariableTableEntry
  constructor: (name, value, address) ->
    @name = name;
    @value = value;
    @address = address;
    @changed = false;
    @changedExpiresAt = 0;

  getName: ->
    return @name

  getValue: ->
    return @value

  getAddress: ->
    return @address

  isChanged: ->
    return @changed and !@isChangedExpired();

  setChanged: (isChanged) ->
    @changed = isChanged;
    # Changed flag expires after 20 milliseconds
    if isChanged
      @changedExpiresAt = new Date().getTime() + 20;

  setChangedExpiresAt: (time) ->
    @changedExpiresAt = time;

  getChangedExpiresAt: ->
    return @changedExpiresAt;

  isChangedExpired: ->
    currentTime = new Date().getTime();
    return @changedExpiresAt < currentTime;

  equals: (other) ->
    if !other?
      return false;
    if other.getName().valueOf() isnt @name.valueOf()
      return false;
    if other.getValue().valueOf() isnt @value.valueOf()
      return false;
    if other.getAddress().valueOf() isnt @address.valueOf()
      return false;
    return true;
