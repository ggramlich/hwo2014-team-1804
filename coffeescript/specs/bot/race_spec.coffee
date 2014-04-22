race = require('../../lib/bot/race')()
expect = require 'must'

expect::approximate = (value, epsilon = 0.0001) -> @between(value - epsilon, value + epsilon)

createPosition = race.createPosition

describe 'Race distance calculation', ->
  before ->
    @race = race.create require './samplerace'

  it 'results in 0 for beginning of first piece', ->
    piecePosition = createPosition 0, 0.0
    expect(@race.distance piecePosition).to.equal 0.0

  it 'results in inPieceDistance for first piece', ->
    piecePosition = createPosition 0, 50.12345
    expect(@race.distance piecePosition).to.equal 50.12345

  it 'results in length of first piece for beginning of second piece', ->
    piecePosition = createPosition 1, 0.0
    expect(@race.distance piecePosition).to.equal 100.0

  it 'can handle difference of two positions', ->
    piecePosition = createPosition(1, 0.0)
    initialPosition = createPosition(0, 0.0)
    expect(@race.distance piecePosition, initialPosition).to.equal 100.0

  it 'can handle difference of two positions with initialPosition not 0', ->
    piecePosition = createPosition(1, 0.0)
    initialPosition = createPosition(0, 55.5)
    expect(@race.distance piecePosition, initialPosition).to.equal 44.5

  it 'can handle difference of two positions with different laps', ->
    piecePosition = createPosition(0, 10.0, 3)
    initialPosition = createPosition(39, 40, 2) # last piece length 90
    expect(@race.distance piecePosition, initialPosition).to.equal 60.0

  it 'can handle difference of two positions with different laps even on negative lap', ->
    piecePosition = createPosition(0, 10.0, 0)
    initialPosition = createPosition(39, 40, -1) # last piece length 90
    expect(@race.distance piecePosition, initialPosition).to.equal 60.0

  xit 'can handle bended pieces', ->
    piecePosition = createPosition(5, 0.0)
    initialPosition = createPosition(4, 0.0)
    expect(@race.distance piecePosition, initialPosition).to.approximate(86.3937)
