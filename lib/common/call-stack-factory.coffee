messageUtils         = require('../messaging/message-utils').getInstance()

class CallStackFactory
  constructor: (serializedState) ->

  fromString: (string) ->
    console.log "Creating Call stack from string. "
    callStack = new Array();
    splitted = string?.split(messageUtils.getDelimiter());
    for i in [1 .. splitted.length]
      if splitted[i]?
        callStack.push(splitted[i]);
    return callStack;
    
module.exports =
class CallStackFactoryProvider
  instance = null
  @getInstance: ->
    instance ?= new CallStackFactory
