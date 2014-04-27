CoolBeans = require 'CoolBeans'
container = new CoolBeans require '../../production-module'

physics = container.get 'physics'

expect = require 'must'
# Do not output stack trace for failed assertions
Error.captureStackTrace = null

expect::approximate = (value, epsilon = 0.0001) -> @between(value - epsilon, value + epsilon)

describe 'The physics', ->
  beforeEach ->
    @myPhysics = physics.create()

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

    {acceleration, velocity, distance, throttle} = physics.predictVelocityAndAcceleration ratios, current
    expect(acceleration).to.approximate (5 - 1) / 50
    expect(velocity).to.approximate 1 + acceleration
    expect(throttle).to.equal 0.5
    expect(distance).to.approximate 1 + acceleration

  it 'can create and instance with reasonable defaults and adjustments', ->
    # max velocity = 9 * 0.8 = 7.2
    dataPoint1 =
      throttle: 0.8
      velocity: 1.8
      acceleration: (7.2 - 1.8) / 51

    dataPoint2 =
      throttle: 0.8
      velocity: 4.0
      acceleration: (7.2 - 4.0) / 51

    {throttleFactor, accelerationRatio} = @myPhysics.throttleAndAccelerationRatio
    expect(throttleFactor).to.approximate 10.0
    expect(accelerationRatio).to.approximate 49.0

    @myPhysics.initThrottleAndAccelerationRatio dataPoint1, dataPoint2

    {throttleFactor, accelerationRatio} = @myPhysics.throttleAndAccelerationRatio
    expect(throttleFactor).to.approximate 9.0
    expect(accelerationRatio).to.approximate 51.0

  it 'predicts next velocity and acceleration from throttle and default ratios', ->
    current =
      throttle: 0.5
      velocity: 1

    {acceleration, velocity, distance, throttle} = @myPhysics.predictVelocityAndAcceleration current
    expect(acceleration).to.approximate (5 - 1) / 50
    expect(velocity).to.approximate 1 + acceleration
    expect(throttle).to.equal 0.5
    expect(distance).to.approximate 1 + acceleration

  it 'predicts next velocity and acceleration from throttle and default ratios for multiple ticks', ->
    current =
      throttle: 0.5
      velocity: 1

    next = @myPhysics.predictVelocityAndAcceleration current
    second = @myPhysics.predictVelocityAndAcceleration next

    {acceleration, velocity, distance, throttle} = @myPhysics.predictVelocityAndAcceleration current, 0.5, 2
    expect(acceleration).to.approximate second.acceleration
    expect(velocity).to.approximate 1 + next.acceleration + second.acceleration
    expect(throttle).to.equal 0.5
    expect(distance).to.approximate next.velocity + second.velocity

  it 'can advice the optimal throttle for target velocity', ->
    currentVelocity = 2

    # sanity check for expected values below
    expect(@myPhysics.predictVelocity(currentVelocity, 0.7)).to.approximate 2.1
    expect(@myPhysics.predictVelocity(currentVelocity, 0.1)).to.approximate 1.98

    expect(@myPhysics.optimalThrottle 2.2, currentVelocity).to.equal 1.0
    expect(@myPhysics.optimalThrottle 1.9, currentVelocity).to.equal 0.0
    expect(@myPhysics.optimalThrottle 2.0, currentVelocity).to.approximate 0.2
    expect(@myPhysics.optimalThrottle 2.1, currentVelocity).to.approximate 0.7
    expect(@myPhysics.optimalThrottle 1.98, currentVelocity).to.approximate 0.1

  it 'can advice the optimal throttle for target velocity at a given distance', ->
    # assuming that we can go as fast as we want before we reach the distance
    currentVelocity = 5

    tick1 = @myPhysics.predictVelocityAndAcceleration {velocity: currentVelocity, throttle: 1.0}
    tick2 = @myPhysics.predictVelocityAndAcceleration tick1, 1.0
    tick3 = @myPhysics.predictVelocityAndAcceleration tick2, 0.0
    tick4 = @myPhysics.predictVelocityAndAcceleration tick3, (@myPhysics.optimalThrottle 5.0, tick3.velocity)
#    console.log tick1
#    console.log tick2
#    console.log tick3
#    console.log tick4

    expect(@myPhysics.optimalThrottleForVelocityInDistance 5, tick4.distance, currentVelocity).to.equal 1.0
    expect(@myPhysics.optimalThrottleForVelocityInDistance 5, tick4.distance - tick1.distance, tick1.velocity).to.equal 1.0
    expect(@myPhysics.optimalThrottleForVelocityInDistance 5, tick4.distance - tick2.distance, tick2.velocity).to.equal 0.0
    expect(@myPhysics.optimalThrottleForVelocityInDistance 5, tick4.distance - tick3.distance, tick3.velocity).to.equal tick4.throttle



