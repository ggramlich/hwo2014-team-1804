module.exports =
  initialConnection:
    module: 'lib/initialConnection'
    autowire: on
  messages:
    module: 'lib/initialConnection/messages'
  connections:
    module: 'lib/initialConnection/connections'
    autowire: on
  bot:
    module: 'lib/bot'
  async:
    module: 'async'
  net:
    module: 'net'
  JSONStream:
    module: 'JSONStream'
