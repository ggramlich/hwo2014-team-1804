module.exports = (objects) ->

  class Physics
    constructor: ->
      @throttleAndAccelerationRatio =
        throttleFactor: 10.0
        accelerationRatio: 49.0

    initThrottleAndAccelerationRatio: (dataPoint1, dataPoint2) ->
      @throttleAndAccelerationRatio = getThrottleAndAccelerationRatio dataPoint1, dataPoint2

    predictVelocityAndAcceleration: (originalCurrent, throttle, ticks = 1) ->
      current = objects.clone originalCurrent
      if throttle?
        current.throttle = throttle
      predictVelocityAndAcceleration @throttleAndAccelerationRatio, current, ticks

    predictVelocity: (velocity, throttle, ticks = 1) -> @predictVelocityAndAcceleration({velocity}, throttle, ticks).velocity

    optimalThrottle: (targetVelocity, currentVelocity) ->
      {throttleFactor, accelerationRatio} = @throttleAndAccelerationRatio
      throttle = ((targetVelocity - currentVelocity) * (accelerationRatio + 1) + currentVelocity) / throttleFactor
      if throttle > 1.0
        1.0
      else if throttle < 0.0
        0.0
      else
        throttle

    distanceToBrakeToVelocity: (targetVelocity, velocity) ->
      totalDistance = 0
      while velocity > targetVelocity
        next = @predictVelocityAndAcceleration {velocity}, 0.0
        {velocity, distance} = next
        totalDistance += distance
      totalDistance

    optimalThrottleForVelocityInDistance: (targetVelocity, distance, currentVelocity) ->
      if distance - currentVelocity > @distanceToBrakeToVelocity targetVelocity, currentVelocity
        1.0
      else
        @optimalThrottle(targetVelocity, currentVelocity)


  getThrottleAndAccelerationRatio = (dataPoint1, dataPoint2) ->
    {throttle1, velocity1, acceleration1} = dataPoint1
    {throttle2, velocity2, acceleration2} = dataPoint2

    a1 = dataPoint1.acceleration
    a2 = dataPoint2.acceleration

    return if dataPoint1.throttle isnt dataPoint2.throttle or a1 is a2

    v1 = dataPoint1.velocity
    v2 = dataPoint2.velocity

    targetVelocity = (a1 * v2 - a2 * v1) / (a1 - a2)
    throttleFactor = targetVelocity / dataPoint1.throttle
    accelerationRatio = (targetVelocity  - v1) / a1

    {throttleFactor, accelerationRatio}

  predictVelocityAndAcceleration = (ratios, current, ticks = 1) ->
    {throttleFactor, accelerationRatio} = ratios
    {velocity, throttle} = current

    acceleration = (throttle * throttleFactor - velocity) / (accelerationRatio + 1)
    velocity = velocity + acceleration
    distance = velocity + (current.distance ? 0)
    next = {acceleration, velocity, distance, throttle}
    if ticks > 1
      predictVelocityAndAcceleration ratios, next, ticks - 1
    else
      next


  create = -> new Physics()

  return {getThrottleAndAccelerationRatio, predictVelocityAndAcceleration, create}
