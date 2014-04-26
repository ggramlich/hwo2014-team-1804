CoolBeans = require 'CoolBeans'
container = new CoolBeans require '../../production-module'

race = container.get 'race'
expect = require 'must'

sampleRace = require './samplerace'
samplePositions = require './samplepositions'

expect::approximate = (value, epsilon = 0.0001) -> @between(value - epsilon, value + epsilon)

createPosition = race.createPosition

describe 'The race', ->
  beforeEach ->
    @race = race.create sampleRace
    @redLane = @race.getCarLane 'red'

  describe 'car lane', ->
    piecePosition = createPosition 0, 0.0

    it 'returns lane 0, 0 as default', ->
      expect(@redLane.at piecePosition).to.eql startLaneIndex: 0, endLaneIndex: 0

    it 'returns the given lane for the position', ->
      @redLane.add createPosition 0, 0.0, 0, 1, 0
      expect(@redLane.at piecePosition).to.eql startLaneIndex: 1, endLaneIndex: 0

    it 'does not change the lanes stored by race', ->
      @redLane.add createPosition 0, 0.0, 0, 1, 1
      expect(@race.getCarLane('red').at piecePosition).to.eql startLaneIndex: 0, endLaneIndex: 0

    it 'reflects the lanes stored by the race so far', ->
      @race.addCarPositions samplePositions[0]
      lane = @race.getCarLane('red')
      expect(@race.getCarLane('red').at piecePosition).to.eql startLaneIndex: 0, endLaneIndex: 0
      expect(@race.getCarLane('blue').at piecePosition).to.eql startLaneIndex: 1, endLaneIndex: 1

    it 'returns the given endLaneIndex as lanes for succeeding positions (i.e. no switch assumed afterwards)', ->
      @redLane.add createPosition 0, 0.0, 0, 0, 1
      expect(@redLane.at createPosition 5, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1

    it 'returns an appropriate series of lanes', ->
      @redLane.add createPosition 0, 0.0, 0, 0, 1
      @redLane.add createPosition 3, 0.0, 0, 1, 1
      @redLane.add createPosition 5, 0.0, 0, 1, 0
      @redLane.add createPosition 39, 0.0, 0, 0, 1
      @redLane.add createPosition 3, 0.0, 1, 1, 0

      expect(@redLane.at createPosition 0, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 1
      expect(@redLane.at createPosition 1, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(@redLane.at createPosition 3, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(@redLane.at createPosition 4, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(@redLane.at createPosition 5, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 0
      expect(@redLane.at createPosition 6, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 0
      expect(@redLane.at createPosition 38, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 0
      expect(@redLane.at createPosition 39, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 1
      expect(@redLane.at createPosition 0, 0.0, 1).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(@redLane.at createPosition 2, 0.0, 1).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(@redLane.at createPosition 3, 0.0, 1).to.eql startLaneIndex: 1, endLaneIndex: 0
      expect(@redLane.at createPosition 4, 0.0, 1).to.eql startLaneIndex: 0, endLaneIndex: 0

  describe 'distance calculation', ->
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
      piecePosition = createPosition 1, 0.0
      initialPosition = createPosition 0, 0.0
      expect(@race.distance piecePosition, initialPosition).to.equal 100.0

    it 'can handle difference of two positions with initialPosition not 0', ->
      piecePosition = createPosition 1, 0.0
      initialPosition = createPosition 0, 55.5
      expect(@race.distance piecePosition, initialPosition).to.equal 44.5

    it 'can handle difference of two positions with different laps', ->
      piecePosition = createPosition 0, 10.0, 3
      initialPosition = createPosition 39, 40, 2 # last piece length 90
      expect(@race.distance piecePosition, initialPosition).to.equal 60.0

    it 'can handle difference of two positions with different laps even on negative lap', ->
      piecePosition = createPosition 0, 10.0, 0
      initialPosition = createPosition 39, 40, -1 # last piece length 90
      expect(@race.distance piecePosition, initialPosition).to.equal 60.0

    it 'calculates distance for bended pieces given the lanes', ->
      piecePosition = createPosition 5, 0.0
      initialPosition = createPosition 4, 0.0

      # lane 0 is outer
      @redLane.add createPosition 4, 0.0, 0, 0, 0
      expect(@race.distance piecePosition, initialPosition, @redLane).to.approximate(86.3937)

      # lane 1 is inner
      @redLane.add createPosition 4, 0.0, 0, 1, 1
      expect(@race.distance piecePosition, initialPosition, @redLane).to.approximate(70.6858)


    it 'calculates distance for bended pieces given the car color', ->
      piecePosition = createPosition 5, 0.0
      initialPosition = createPosition 4, 0.0
      @race.addCarPositions [
        {
          id: color: 'red'
          piecePosition: createPosition 4, 0.0, 0, 0, 0
        }
        {
          id: color: 'blue'
          piecePosition: createPosition 4, 0.0, 0, 1, 1
        }
      ]
      expect(@race.distance piecePosition, initialPosition, 'red').to.approximate(86.3937)
      expect(@race.distance piecePosition, initialPosition, 'blue').to.approximate(70.6858)

