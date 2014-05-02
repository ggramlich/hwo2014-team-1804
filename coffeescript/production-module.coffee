module.exports =
  initialConnection:
    module: 'lib/initialConnection/initialConnection'
    autowire: on
  messages:
    module: 'lib/initialConnection/messages'
  connections:
    module: 'lib/initialConnection/connections'
    autowire: on
  race:
    module: 'lib/bot/race'
    autowire: on
  physics:
    module: 'lib/bot/physics'
    autowire: on
  bot:
    module: 'lib/bot/bot'
    autowire: on
  async:
    module: 'async'
  net:
    module: 'net'
  JSONStream:
    module: 'JSONStream'
  objects:
    module: 'objects'
  winston:
    module: 'winston'
  rref:
    module: 'rref'
