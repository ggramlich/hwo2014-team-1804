net        = require("net")
JSONStream = require('JSONStream')

module.exports = (botData, serverPort, serverHost) ->
  initialMessage = {msgType: "join", data: botData}
  initialMessage =
    msgType: "createRace"
    data:
      botId: botData
      trackName: "keimola"
      password: "gggg"
      carCount: 1

  client = net.connect serverPort, serverHost, () ->
    send(initialMessage)

  send = (json) ->
    jsonString = JSON.stringify(json)
    console.log 'SENDING: ' + jsonString
    client.write jsonString
    client.write '\n'

  jsonStream = client.pipe(JSONStream.parse())

  createControl = ->
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

  jsonStream.on 'error', ->
    console.log "disconnected"

  control: (bot) ->
    jsonStream.on 'data', (data) ->
      dataString = JSON.stringify(data)
      console.log 'RECEIVE: ' + dataString
      bot[data.msgType]? data, createControl()

