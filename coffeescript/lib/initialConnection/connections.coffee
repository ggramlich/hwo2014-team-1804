module.exports = (net, JSONStream) ->
  for: (serverPort, serverHost) ->
    create: (message, callback) ->
      client = net.connect serverPort, serverHost, () ->
        send message
        callback()

      send = (json) ->
        jsonString = JSON.stringify(json)
        console.log 'SENDING: ' + jsonString
        client.write jsonString
        client.write '\n'

      jsonStream = client.pipe(JSONStream.parse())

      return {send, jsonStream}
