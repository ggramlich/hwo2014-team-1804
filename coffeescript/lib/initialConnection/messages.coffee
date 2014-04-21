module.exports =
  initial: (botData, testRace) ->
    carCount = 1
    if testRace?
      carCount = testRace.carCount ? 1
      createData = (index, password = null) ->
        messageData =
          botId:
            key: botData.key
            name: botData.name + index
          trackName: testRace.trackName
          carCount: carCount
        if password?
          messageData.password = password
        messageData

      if testRace.joinOnly
        password = null
        initialMessages = [
          msgType: "joinRace"
          data: createData('')
        ]
      else
        password = 'gg'
        initialMessages = [
          msgType: "createRace"
          data: createData('', password)
        ]
      index = 1
      while initialMessages.length < carCount
        initialMessages.push
          msgType: "joinRace"
          data: createData(index++, password)
    else
      initialMessages = [msgType: "join", data: botData]
    initialMessages
