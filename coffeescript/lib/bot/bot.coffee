module.exports = (winston, physics, rref) ->
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
      @maxSlipAngle = 0
      @slipTick = 0

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
      @angleStuff()

      @adjustVelocity()
      @maxSlipAngle = Math.max(@maxSlipAngle, @race.getCarAngle(@color))

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

    lapFinished: (data, control) ->
      angleDiff = @race.maxAngle - @maxSlipAngle
      if angleDiff > 0
        @factorMaxSlip = @factorMaxSlip * (1 + angleDiff * angleDiff / 10000)
      @maxSlipAngle = 0
      control.ignore()

    reduceFactorMaxSlip: ->
      @factorMaxSlip = 0.98 * @factorMaxSlip

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
      winston.verbose "#{@logPrefix()};throttleAndAccelerationRatio:", @physics.throttleAndAccelerationRatio

    initMaxSlipFactor: ->
      return if @maxSlipInitialized or @race.getCarAngle(@color) is 0


      a = Math.abs @race.getCarAngle @color
      v = @race.getVelocity @color
      r = @getRadius()
      b = v / r * 180 / Math.PI
      bslip = b - a
      vslip = r * b * Math.PI / 180

      @angleStuff()

      @slipTick = @slipTick + 1
      if @slipTick > 3
        @maxSlipInitialized = yes
        @factorMaxSlip = 0.97 * vslip * vslip / r
        winston.warn @logPrefix()  + ";initMaxSlipFactor;a:#{a}, v:#{v}, r:#{r}, b:#{b}, bs:#{bslip}, vs:#{vslip}, fac:#{@factorMaxSlip}"

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
      log2 = "#{angle};#{angleS};#{angleSC};#{radius}"
      log2a = ";#{predict?.velocity};#{predict?.acceleration}"
      log3 = ";#{@constants?[0]};#{@constants?[1]};#{@constants?[2]};#{@constants?[3]}"
      winston.info log1 + log2 + log3

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
      @targetVelocity = 5.4
      return @adjustThrottle()

      if @race.straightToFinish @color
        @targetVelocity = 100
        return @adjustThrottle()

      if @onBendedPiece() and @predictAngle() > @race.maxAngle
        @targetVelocity = @maxVelocityForRadius @getRadius() / 2
        return @adjustThrottle()

      bendedPieces = @race.bendedPiecesAhead @color

      throttles = for {radius, distance} in bendedPieces
        targetVelocity = @maxVelocityForRadius radius
        @throttleForVelocityInDistance targetVelocity, distance

      @setThrottle(Math.min throttles...)

    predictAngle: ->
      angle = @race.getCarAngle(@color)
      angleS = @race.getAngularSpeed(@color)
      angleSC = @race.getAngularSpeedChange(@color)
      velocity = @race.getVelocity @color
      Math.abs(angle + (velocity + 1) * angleS + velocity * angleSC)

    maxVelocityForRadius: (radius) ->
      # v^2 / r = @factorMaxSlip
      Math.sqrt(@factorMaxSlip * radius)


    adjustThrottle: (distance = 0) ->
      @setThrottle @throttleForVelocityInDistance @targetVelocity, distance

    throttleForVelocityInDistance: (targetVelocity, distance = 0) ->
#      if distance > 0
#        distance += 20
      velocity = @race.getVelocity @color
      @physics.optimalThrottleForVelocityInDistance targetVelocity, distance, velocity

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
    angleStuff: ->
      return if @race.getCarAngle(@color) is 0
      tick = @race.currentTick

#      if @angleParams?
#        return

      if @race.getAngularSpeedChange(@color, tick - 2) isnt 0
        aSC2 = @race.getAngularSpeedChange(@color, tick - 2)
        aSC1 = @race.getAngularSpeedChange(@color, tick - 1)
        aSC0 = @race.getAngularSpeedChange(@color, tick)
        aS3 = @race.getAngularSpeed(@color, tick - 3)
        aS2 = @race.getAngularSpeed(@color, tick - 2)
        aS1 = @race.getAngularSpeed(@color, tick - 1)
        a2 = @race.getCarAngle(@color, tick - 2)
        a3 = @race.getCarAngle(@color, tick - 3)
        a4 = @race.getCarAngle(@color, tick - 4)
        v2 = @race.getVelocity(@color, tick - 2)
        v1 = @race.getVelocity(@color, tick - 1)
        v0 = @race.getVelocity(@color, tick)

        c3 = ((aSC0 - aS1 * (aSC1 / aSC2 - 1)) / aSC2) - 1
        c2 = c3 / @race.getVelocity(@color)
        c1 = aSC1 / aSC2 - 1 - c3

        c0 = aSC0
        r = @getRadius()

        solved = rref [
          [v2*v2/r, aS1, v2 * (aS1 + a2), aSC0]
          [v1*v1/r, aS2, v1 * (aS2 + a3), aSC1]
          [v0*v0/r, aS3, v0 * (aS3 + a4), aSC2]
        ]
        @constants = (row[-1..][0] for row in solved)
        @constants.push @constants[0] * (v0*v0) / r


        #winston.warn @logPrefix() + ";aSC2;aSC1;aSC0;aS1;c3;c2;c1;c0"
        #winston.warn @logPrefix() + ";#{aSC2};#{aSC1};#{aSC0};#{aS1};#{c3};#{c2};#{c1};#{c0}"

        @angleParams = {c0, c1, c2}

        #winston.warn @logPrefix() + ";#{@constants?[0]};#{@constants?[1]};#{@constants?[2]}"


