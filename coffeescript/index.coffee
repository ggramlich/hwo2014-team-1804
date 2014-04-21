CoolBeans = require 'CoolBeans'
container = new CoolBeans require './production-module'

[serverHost, serverPort, name, key] = process.argv[2..]

# keimola, germany, usa
if process.env.TESTRACE?
  testRace =
    trackName: 'keimola'
    carCount: 4
    joinOnly: off

console.log "I'm #{name} and connect to #{serverHost}:#{serverPort}"

botData = {name, key}

connectAndCreateBotController = container.get 'initialConnection'
Bots = [container.get 'bot']

botController = connectAndCreateBotController botData, serverPort, serverHost, testRace
botController.control Bots
