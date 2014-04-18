connectAndCreateBotController = require './lib/initialConnection'
bot = require './lib/bot'

serverHost = process.argv[2]
serverPort = process.argv[3]
botName = process.argv[4]
botKey = process.argv[5]

console.log("I'm", botName, "and connect to", serverHost + ":" + serverPort)

botData =
  name: botName
  key: botKey

botController = connectAndCreateBotController botData, serverPort, serverHost
botController.control bot
