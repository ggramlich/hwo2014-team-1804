module.exports =
  initial: (botData, testRace) ->
    carCount = 1
    if testRace?
      carCount = testRace.carCount ? 1
      createData = (index) ->
        botId:
          key: botData.key
          name: botData.name + index
        trackName: testRace.trackName
        password: "gggg"
        carCount: carCount
      initialMessages = [
        msgType: "createRace"
        data: createData('')
      ]
      index = 1
      while initialMessages.length < carCount
        initialMessages.push
          msgType: "joinRace"
          data: createData(index++)
    else
      initialMessages = [msgType: "join", data: botData]
    initialMessages
