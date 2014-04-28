CoolBeans = require 'CoolBeans'
container = new CoolBeans require './production-module'

[serverHost, serverPort, name, key] = process.argv[2..]

winston = container.get 'winston'
# winston.level = 'debug' # most
# winston.level = 'verbose' # a little more than info

# keimola, germany, usa, france
if process.env.TESTRACE?
  testRace =
    trackName: 'usa'
    carCount: 3
    joinOnly: off

winston.verbose "I'm #{name} and connect to #{serverHost}:#{serverPort}"

botData = {name, key}

connectAndCreateBotController = container.get 'initialConnection'
Bots = [container.get 'bot']

botController = connectAndCreateBotController botData, serverPort, serverHost, testRace
botController.control Bots
