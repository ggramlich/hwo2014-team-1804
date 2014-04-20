module.exports = (messages, async, connections, race) ->
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

  return (botData, serverPort, serverHost, testRace) ->
    initialMessages = messages.initial botData, testRace

    botStarter = (Bot, initialMessage) ->
      (callback) ->
        bot = null
        carData = null
        connection = connections.for(serverPort, serverHost).create(initialMessage, callback)
        jsonStream = connection.jsonStream

        jsonStream.on 'error', ->
          console.log "disconnected"

        jsonStream.on 'data', (data) ->
          dataString = JSON.stringify(data)
          console.log 'RECEIVE: ' + dataString

          msgType = data.msgType
          if msgType is 'yourCar'
            carData = data.data
          else if msgType is 'gameInit'
            bot = new Bot carData, race.create(data.data.race)
          bot?[msgType]? data, createControl(connection)


    control: (originalBots) ->
      Bots = []
      while Bots.length < initialMessages.length
        # append all Bots of the originalBots array
        for Bot in originalBots
          Bots.push Bot

      starters = (botStarter(Bots[messageIndex], initialMessages[messageIndex]) for messageIndex in [0..(initialMessages.length - 1)])

      async.series(starters, ->)
