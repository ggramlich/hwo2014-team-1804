module.exports = (winston, physics) ->
  TOLERANCE = 0.0001

  class Bot
    logOnEveryNthTick = 1
    headerLogged = no
    logHeader = ->
      unless headerLogged
        winston.info ";gameTick;color;lap;pieceIndex;normalizedIndex;inPieceDistance;throttle;velocity;acceleration;angle;radius;predictVelocity;predictAcceleration"
        headerLogged = yes

    constructor: ({@name, @color}, @race) ->
      logHeader()
      @physics = physics.create()
      @throttles = []

#      if @color is 'red'
#        @throttle = 0.7
#        @switchRight = on
#      else if @color is 'blue'
#        @throttle = 0.9
#        @switchRight = off
#      else if @color is 'yellow'
#        @throttle = 0.8
#      else if @color is 'green'
#        @throttle = 0.7

      @lastSwitch = 0
      # @throttle = 0.65
      @targetVelocity = 6.54

    switchDirection: ->
      if @switchRight
        'Right'
      else
        'Left'

    myPosition:  ->
      @race.getPiecePosition @color

    initPhysicsParameters: ->
      return if @throttles.length isnt 4

      dataPoint = (tick) =>
        acceleration: @race.getAcceleration @color, tick
        velocity: @race.getVelocity @color, tick
        throttle: @throttles[tick]

      tick = @race.currentTick
      @physics.initThrottleAndAccelerationRatio dataPoint(tick - 2), dataPoint(tick - 1)
      winston.verbose @physics.throttleAndAccelerationRatio

    adjustThrottle: ->
      velocity = @race.getVelocity @color
      @setThrottle @physics.optimalThrottle @targetVelocity, velocity

    setThrottle: (throttle) ->
      if throttle < 0
        @throttle = 0.0
      else if throttle > 1
        @throttle = 1.0
      else
        @throttle = throttle

    prediction: (throttle) ->
      velocity = @race.getVelocity @color
      @physics.predictVelocityAndAcceleration {velocity, throttle}

    logCurrent: ->
      gameTick = @race.currentTick
      return if (gameTick % logOnEveryNthTick)

      normalizedIndex = @race.getNormalizedPieceIndex @color
      velocity = @race.getVelocity @color
      acceleration = @race.getAcceleration @color
      angle = @race.getCarAngle @color
      {pieceIndex, inPieceDistance, lap} = @myPosition()
      radius = @race.getPiece(@color).radius ? 999999
      throttle = @throttle
      predict = @prediction throttle
      winston.info ";#{gameTick};#{@color};#{lap};#{pieceIndex};#{normalizedIndex};#{inPieceDistance};#{throttle};#{velocity};#{acceleration};#{angle};#{radius};#{predict?.velocity};#{predict?.acceleration}"


    carPositions: (data, control) ->
      @initPhysicsParameters()
      @adjustThrottle()
      if @race.getCarAngle(@color) > 0
        console.log @race.getVelocity(@color), @race.getCarAngle(@color)
        exit()
      #        if 35 <= normalizedIndex <= 43
      #          @throttle = 0.0
      #        else if 75 <= normalizedIndex <= 83
      #          @throttle = 0.2



      @logCurrent()
      control.throttle @throttle
      @throttles[@race.currentTick] = @throttle
