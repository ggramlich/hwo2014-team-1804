connectAndCreateBotController = require './lib/initialConnection'
Bot = require './lib/bot'
Bots = [Bot]

serverHost = process.argv[2]
serverPort = process.argv[3]
botName = process.argv[4]
botKey = process.argv[5]

if process.env.TESTRACE?
  testRace =
    trackName: 'keimola'
    carCount: 4

console.log "I'm #{botName} and connect to #{serverHost}:#{serverPort}"

botData =
  name: botName
  key: botKey

botController = connectAndCreateBotController botData, serverPort, serverHost, testRace
botController.control Bots