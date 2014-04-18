net        = require("net")
JSONStream = require('JSONStream')

module.exports = (serverPort, serverHost) ->
  create: (message) ->
    client = net.connect serverPort, serverHost, () ->
      send(message)

    send = (json) ->
      jsonString = JSON.stringify(json)
      console.log 'SENDING: ' + jsonString
      client.write jsonString
      client.write '\n'

    jsonStream = client.pipe(JSONStream.parse())

    return {send, jsonStream}
