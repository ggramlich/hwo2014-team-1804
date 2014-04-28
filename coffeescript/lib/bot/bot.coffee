module.exports = (winston, physics) ->
  class Bot
    logOnEveryNthTick = 1
    headerLogged = no
    logHeader = ->
      unless headerLogged
        winston.info ";gameTick;color;lap;pieceIndex;normalizedIndex;inPieceDistance;throttle;velocity;acceleration;angle;angleS;angleSC;radius;predictVelocity;predictAcceleration"
        headerLogged = yes

    constructor: ({@name, @color}, @race) ->
      logHeader()
      @physics = physics.create()
      @throttles = []
      @maxSlipInitialized = no
      @factorMaxSlip = 0.5

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

    # msgType
    carPositions: (data, control) ->
      @initPhysicsParameters()
      @initMaxSlipFactor()

      @adjustVelocity()


      if @race.currentTick < 4
        @throttle = 1.0

      @logCurrent()
      control.throttle @throttle
      @throttles[@race.currentTick] = @throttle

    # msgType
    crash: (data, control) ->
      winston.verbose data
      if data.data.color is @color
        winston.info "#{@logPrefix()};Crash, Curved vel old #{@factorMaxSlip}"
        @reduceFactorMaxSlip()
        winston.info "#{@logPrefix()};Crash, Curved vel new #{@factorMaxSlip}"
      control.ignore()

    reduceFactorMaxSlip: ->
      @factorMaxSlip = 0.975 * @factorMaxSlip

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

    initMaxSlipFactor: ->
      return if @maxSlipInitialized or @race.getCarAngle(@color) is 0

      a = Math.abs @race.getCarAngle @color
      v = @race.getVelocity @color
      r = @getRadius()
      b = v / r * 180 / Math.PI
      bslip = b - a
      vslip = r * b * Math.PI / 180
      @factorMaxSlip = vslip * vslip / r
      console.log @logPrefix()  + ";initMaxSlipFactor;a:#{a}, v:#{v}, r:#{r}, b:#{b}, bs:#{bslip}, vs:#{vslip}, fac:#{@factorMaxSlip}"
      @maxSlipInitialized = yes

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

      velocity = @race.getVelocity @color
      acceleration = @race.getAcceleration @color
      angle = @race.getCarAngle @color
      radius = @getRadius()
      throttle = @throttle
      predict = @prediction throttle
      angleS = @race.getAngularSpeed @color
      angleSC = @race.getAngularSpeedChange @color

      log1 = "#{@logPrefix()};#{throttle};#{velocity};#{acceleration};"
      log2 = "#{angle};#{angleS};#{angleSC};#{radius};#{predict?.velocity};#{predict?.acceleration}"
      winston.info log1 + log2

    logPrefix: ->
      gameTick = @race.currentTick
      normalizedIndex = @race.getNormalizedPieceIndex @color
      {pieceIndex, inPieceDistance, lap} = @myPosition()
      ";#{gameTick};#{@color};#{lap};#{pieceIndex};#{normalizedIndex};#{inPieceDistance}"

    onBendedPiece: -> @race.getPiece(@color).radius?
    getRadius: ->
      if @onBendedPiece()
        pieceIndex = @race.getNormalizedPieceIndex @color
        @getRadiusOnLane pieceIndex
      else
        999999

    getRadiusOnLane: (pieceIndex) -> @race.getRadiusOnLane pieceIndex, @race.getCarLane(@color)

    adjustVelocity: ->
      if @race.straightToFinish @color
        @targetVelocity = 50
        @adjustThrottle()
        return

      straightDistance = @race.straightDistanceAhead(@color)
      bendedPieceIndex = @race.nextBendedPieceIndex(@color)
      radius = @race.getRadiusOnLane bendedPieceIndex, @race.getCarLane(@color)
      @targetVelocity = @maxVelocityForRadius radius
      @adjustThrottle straightDistance

    maxVelocityForRadius: (radius) ->
      # v^2 / r = 0.39

      Math.sqrt(@factorMaxSlip * radius)


    adjustThrottle: (distance = 0) ->
      velocity = @race.getVelocity @color
      @setThrottle @physics.optimalThrottleForVelocityInDistance @targetVelocity, distance, velocity


#    predictAngleSpeedChange: ->
#      return 0 unless @angleParams?
#      tick = @race.currentTick
#      {c0, c1, c2} = @angleParams
#      velocity = @race.getVelocity @color
#      angle2 = @race.getCarAngle(@color, tick - 2)
#      angularSpeed1 = @race.getAngularSpeed(@color, tick - 1)
#      c0 + (angularSpeed1 * c1 + c2 * velocity) + angle2 * c2 * velocity
#
#
#    angleStuff: ->
#      return if @race.getCarAngle(@color) is 0
#      tick = @race.currentTick
#
#      if @angleParams?
#        return
#
#      if @race.getAngularSpeedChange(@color, tick - 2) > 0
#        aSC2 = @race.getAngularSpeedChange(@color, tick - 2)
#        aSC1 = @race.getAngularSpeedChange(@color, tick - 1)
#        aSC0 = @race.getAngularSpeedChange(@color, tick)
#        aS1 = @race.getAngularSpeed(@color, tick - 1)
#
#        c3 = ((aSC0 - aS1 * (aSC1 / aSC2 - 1)) / aSC2) - 1
#        c2 = c3 / @race.getVelocity(@color)
#        c1 = aSC1 / aSC2 - 1 - c3
#
#        c0 = aSC0
#
#        @angleParams = {c0, c1, c2}




