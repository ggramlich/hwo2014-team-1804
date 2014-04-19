messages = require './messages'
async    = require 'async'

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

module.exports = (botData, serverPort, serverHost, testRace) ->
  connections = (require './connections')(serverPort, serverHost)
  initialMessages = messages.initial botData, testRace

  botStarter = (Bot, initialMessage) ->
    (callback) ->
      bot = null
      connection = connections.create(initialMessage, callback)
      jsonStream = connection.jsonStream

      jsonStream.on 'error', ->
        console.log "disconnected"

      jsonStream.on 'data', (data) ->
        if data.msgType is 'yourCar'
          bot = new Bot data.data
        dataString = JSON.stringify(data)
        console.log 'RECEIVE: ' + dataString
        bot?[data.msgType]? data, createControl(connection)


  control: (originalBots) ->
    Bots = []
    while Bots.length < initialMessages.length
      # append all Bots of the originalBots array
      for Bot in originalBots
        Bots.push Bot

    starters = (botStarter(Bots[messageIndex], initialMessages[messageIndex]) for messageIndex in [0..(initialMessages.length - 1)])

    async.series(starters, ->)
