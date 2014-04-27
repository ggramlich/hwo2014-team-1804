module.exports = ->
  getThrottleAndAccelerationRatio: (dataPoint1, dataPoint2) ->
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

  predictVelocityAndAcceleration: (ratios, current) ->
    {throttleFactor, accelerationRatio} = ratios
    currentAcceleration = current.acceleration
    currentVelocity = current.velocity

    throttle = current.throttle

    distance = currentVelocity
    acceleration = (throttle * throttleFactor - currentVelocity) / (accelerationRatio + 1)
    velocity = currentVelocity + acceleration

    {acceleration, velocity, distance, throttle}
