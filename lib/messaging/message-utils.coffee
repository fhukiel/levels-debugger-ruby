module.exports =
class MessageUtils
  @DELIMITER: ';'

  @ASSIGN_SYMBOL: '=*='

  @FINAL_SYMBOL: '/!/'

  @getNewlineSymbol: ->
    return require('os').EOL

  @removeNewlineSymbol: (string) ->
    return string?.replace MessageUtils.getNewlineSymbol(), ''