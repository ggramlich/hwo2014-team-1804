messages   = require './messages'

module.exports = (botData, serverPort, serverHost, testRace) ->
  connections = (require './connections')(serverPort, serverHost)
  initialMessages = messages.initial botData, testRace

  createControl = (connection) ->
    send = connection.send
    called = no
    setTimeout ->
      if not called
        send msgType: "ping"
    , 10
    throttle: (value) ->
      called = yes
      send msgType: "throttle", data: value
    switchLane: (direction) ->
      called = yes
      send msgType: "switchLane", data: direction

  control: (originalBots) ->
    Bots = []
    while Bots.length < initialMessages.length
      # append all Bots of the originalBots array
      for Bot in originalBots
        Bots.push Bot

    messageIndex = 0
    for Bot in Bots
      ((messageIndex) ->
        setTimeout ->
          connection = connections.create(initialMessages[messageIndex])
          jsonStream = connection.jsonStream

          jsonStream.on 'error', ->
            console.log "disconnected"

          bot = new Bot
          jsonStream.on 'data', (data) ->
            dataString = JSON.stringify(data)
            console.log 'RECEIVE: ' + dataString
            bot[data.msgType]? data, createControl(connection)
        , messageIndex * 1000)(messageIndex++)
