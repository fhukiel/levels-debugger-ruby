class MessageUtils
  constructor: (serializedState) ->

  serialize: ->

  destroy: ->

  getDelimiter: ->
    return ";"

  getAssignSymbol: ->
    return "=*=";

  getFinalSymbol: ->
    return "/!/";

  getNewLineSymbol: ->
    return require('os').EOL;

  removeNewLineSymbol: (string) ->
    strCopy = string;
    strCopy = strCopy.replace("\n", "");
    strCopy = strCopy.replace("\r", "");
    return strCopy;

module.exports =
class MessageUtilsProvider
  instance = null
  @getInstance: ->
    instance ?= new MessageUtils
