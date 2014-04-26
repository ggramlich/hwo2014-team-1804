module.exports = (messages, async, connections, race, winston) ->
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
        currentRace = null
        carData = null
        connection = connections.for(serverPort, serverHost).create(initialMessage, callback)
        jsonStream = connection.jsonStream

        jsonStream.on 'error', ->
          winston.error "disconnected"

        jsonStream.on 'data', (data) ->
          dataString = JSON.stringify(data)
          winston.debug 'RECEIVE: ' + dataString

          msgType = data.msgType
          if msgType is 'yourCar'
            carData = data.data
          else if msgType is 'gameInit'
            currentRace = race.create(data.data.race)
            bot = new Bot carData, currentRace
          else if msgType is 'carPositions'
            currentRace?.addCarPositions data.data, data.gameTick ? 0
          else if msgType in ['lapFinished', 'gameStart', 'joinRace', 'finish', 'turboAvailable', 'createRace']
            winston.verbose dataString
          else
            winston.warn dataString

          bot?[msgType]? data, createControl(connection)


    control: (originalBots) ->
      Bots = []
      while Bots.length < initialMessages.length
        # append all Bots of the originalBots array
        for Bot in originalBots
          Bots.push Bot

      starters = (botStarter(Bots[messageIndex], initialMessages[messageIndex]) for messageIndex in [0..(initialMessages.length - 1)])

      async.series(starters, ->)
