net        = require("net")
JSONStream = require('JSONStream')
messages   = require './messages'

module.exports = (botData, serverPort, serverHost, testRace) ->
  initialMessages = messages.initial botData, testRace

  createConnection = (initialMessage) ->
    client = net.connect serverPort, serverHost, () ->
      send(initialMessage)

    send = (json) ->
      jsonString = JSON.stringify(json)
      console.log 'SENDING: ' + jsonString
      client.write jsonString
      client.write '\n'

    jsonStream = client.pipe(JSONStream.parse())

    return {send, jsonStream}

#  connections = (createConnection(initialMessage) for initialMessage in initialMessages)

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
          connection = createConnection(initialMessages[messageIndex])
          jsonStream = connection.jsonStream

          jsonStream.on 'error', ->
            console.log "disconnected"

          bot = new Bot
          jsonStream.on 'data', (data) ->
            dataString = JSON.stringify(data)
            console.log 'RECEIVE: ' + dataString
            bot[data.msgType]? data, createControl(connection)
        , messageIndex * 1000)(messageIndex++)
