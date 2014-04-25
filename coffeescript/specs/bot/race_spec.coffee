CoolBeans = require 'CoolBeans'
container = new CoolBeans require '../../production-module'

race = container.get 'race'
expect = require 'must'

sampleRace = require './samplerace'
samplePositions = require './samplepositions'

expect::approximate = (value, epsilon = 0.0001) -> @between(value - epsilon, value + epsilon)

createPosition = race.createPosition

describe 'The race', ->
  before ->
    @race = race.create sampleRace

  describe 'lane pieces', ->
    piecePosition = createPosition 0, 0.0

    it 'returns lane 0, 0 as default', ->
      lanes = @race.getCarLanes('red')
      expect(lanes.at piecePosition).to.eql startLaneIndex: 0, endLaneIndex: 0

    it 'returns the given lanes for the position', ->
      lanes = @race.getCarLanes('red')
      lanes.add createPosition 0, 0.0, 0, 1, 0
      expect(lanes.at piecePosition).to.eql startLaneIndex: 1, endLaneIndex: 0

    it 'does not change the lanes stored by race', ->
      lanes = @race.getCarLanes('red')
      lanes.add createPosition 0, 0.0, 0, 1, 1
      expect(@race.getCarLanes('red').at piecePosition).to.eql startLaneIndex: 0, endLaneIndex: 0

    it 'reflects the lanes stored by the race so far', ->
      @race.addCarPositions samplePositions[0]
      lanes = @race.getCarLanes('red')
      expect(@race.getCarLanes('red').at piecePosition).to.eql startLaneIndex: 0, endLaneIndex: 0
      expect(@race.getCarLanes('blue').at piecePosition).to.eql startLaneIndex: 1, endLaneIndex: 1

    it 'returns the given endLaneIndex as lanes for succeeding positions (i.e. no switch assumed afterwards)', ->
      lanes = @race.getCarLanes('red')
      lanes.add createPosition 0, 0.0, 0, 0, 1
      expect(lanes.at createPosition 5, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1

    it 'returns an appropriate series of lanes', ->
      lanes = @race.getCarLanes('red')
      lanes.add createPosition 0, 0.0, 0, 0, 1
      lanes.add createPosition 3, 0.0, 0, 1, 1
      lanes.add createPosition 5, 0.0, 0, 1, 0
      lanes.add createPosition 39, 0.0, 0, 0, 1
      lanes.add createPosition 3, 0.0, 1, 1, 0

      expect(lanes.at createPosition 0, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 1
      expect(lanes.at createPosition 1, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(lanes.at createPosition 3, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(lanes.at createPosition 4, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(lanes.at createPosition 5, 0.0).to.eql startLaneIndex: 1, endLaneIndex: 0
      expect(lanes.at createPosition 6, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 0
      expect(lanes.at createPosition 38, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 0
      expect(lanes.at createPosition 39, 0.0).to.eql startLaneIndex: 0, endLaneIndex: 1
      expect(lanes.at createPosition 0, 0.0, 1).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(lanes.at createPosition 2, 0.0, 1).to.eql startLaneIndex: 1, endLaneIndex: 1
      expect(lanes.at createPosition 3, 0.0, 1).to.eql startLaneIndex: 1, endLaneIndex: 0
      expect(lanes.at createPosition 4, 0.0, 1).to.eql startLaneIndex: 0, endLaneIndex: 0

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

