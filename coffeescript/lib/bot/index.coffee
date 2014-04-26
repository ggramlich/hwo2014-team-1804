module.exports = (winston) ->
  class Bot
    headerLogged = no
    constructor: ({@name, @color}, @race) ->
      unless headerLogged
        winston.info "gameTick;color;lap;pieceIndex;inPieceDistance;throttle;velocity;acceleration;angle"
        headerLogged = yes

      if @color is 'red'
        @throttle = 1
        @switchRight = on
      else if @color is 'blue'
        @throttle = 0.9
        @switchRight = off
      else if @color is 'yellow'
        @throttle = 0.8
      else if @color is 'green'
        @throttle = 0.7

      @lastSwitch = 0
      @throttle = 0.65

    switchDirection: ->
      if @switchRight
        'Right'
      else
        'Left'

    myPosition:  ->
      @race.getPiecePosition @color

    carPositions: (data, control) ->
      gameTick = @race.currentTick
      velocity = @race.getVelocity @color
      acceleration = @race.getAcceleration @color
      angle = @race.getCarAngle @color

      {pieceIndex, inPieceDistance, lap} = @myPosition(data.data)
      if (gameTick % 10) is 0
        winston.info "#{gameTick};#{@color};#{lap};#{pieceIndex};#{inPieceDistance};#{@throttle};#{velocity};#{acceleration};#{angle}"
      control.throttle @throttle
#      pieceIndex = carPosition.piecePosition.pieceIndex
#      console.log 'XXXXXXXXXXX'
#      console.log pieceIndex
#      console.log @race.track.pieces
#      console.log @race.track.pieces[pieceIndex + 1]
#      console.log @race.track.pieces[pieceIndex + 1]?.switch?
#      console.log @lastSwitch isnt pieceIndex
#      if @race.track.pieces[pieceIndex + 1]?.switch? and @lastSwitch isnt pieceIndex
#        console.log 'SWITCHX'
#        @lastSwitch = pieceIndex
#        control.switchLane @switchDirection()
#        @switchRight = not @switchRight
#      else
#        control.throttle @throttle
#
#      if data.gameTick is 65
#        if @color is 'red'
#          control.switchLane 'Right'
#        else
#          control.switchLane 'Left'
#      else
#        control.throttle @throttle
