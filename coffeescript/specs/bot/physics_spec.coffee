CoolBeans = require 'CoolBeans'
container = new CoolBeans require '../../production-module'

physics = container.get 'physics'

expect = require 'must'
# Do not output stack trace for failed assertions
Error.captureStackTrace = null

expect::approximate = (value, epsilon = 0.0001) -> @between(value - epsilon, value + epsilon)

describe 'The physics', ->
  it 'calculates max velocity factor and acceleration ratio from two data points', ->
    dataPoint1 =
      throttle: 0.5
      velocity: 1
      acceleration: 4 / 49

    dataPoint2 =
      throttle: 0.5
      velocity: 2
      acceleration: 3 / 49

    {throttleFactor, accelerationRatio} = physics.getThrottleAndAccelerationRatio dataPoint1, dataPoint2
    expect(throttleFactor).to.approximate 10.0
    expect(accelerationRatio).to.approximate 49.0

  it 'predicts next velocity and acceleration from throttle and ratios', ->
    # max velocity = throttleFactor * throttle = 50
    # acceleration = (max velocity - current velocity) / accelerationRatio
    ratios =
      throttleFactor: 10.0
      accelerationRatio: 49.0
    current =
      throttle: 0.5
      velocity: 1
      acceleration: 4 / 49

    {acceleration, velocity, distance, throttle} = physics.predictVelocityAndAcceleration ratios, current
    expect(acceleration).to.approximate (5 - 1) / 50
    expect(velocity).to.approximate 1 + acceleration
    expect(throttle).to.equal 0.5
    expect(distance).to.approximate 1
