CoolBeans = require 'CoolBeans'
container = new CoolBeans require '../../production-module'

race = container.get 'race'
objects = container.get 'objects'

expect = require 'must'
# Do not output stack trace for failed assertions
Error.captureStackTrace = null

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

    it 'calculates length for bended pieces given the lane', ->
      # lane 0 is default
      # lane 0 is outer lane on 4 and 8, but inner lane on 29
      expect(@race.track.pieceLength 4, @redLane).to.approximate 86.3937
      expect(@race.track.pieceLength 8, @redLane).to.approximate 82.4668
      expect(@race.track.pieceLength 29, @redLane).to.approximate 70.6858

      @redLane.add createPosition 4, 0.0, 0, 1, 1
      @redLane.add createPosition 8, 0.0, 0, 1, 1
      @redLane.add createPosition 29, 0.0, 0, 1, 1
      # lane 1 is inner lane on 4 and 8, but outer lane on 29
      expect(@race.track.pieceLength 4, @redLane).to.approximate 70.6858
      expect(@race.track.pieceLength 8, @redLane).to.approximate 74.6128
      expect(@race.track.pieceLength 29, @redLane).to.approximate 86.3938


    it 'calculates distance for bended pieces given the car color', ->
      # Starting from piece 3 of length 100
      piecePosition = createPosition 5, 0.0
      initialPosition = createPosition 3, 0.0
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
      expect(@race.distance piecePosition, initialPosition, 'red').to.approximate(100 + 86.3937)
      expect(@race.distance piecePosition, initialPosition, 'blue').to.approximate(100 + 70.6858)

    it 'provides the radius on lane', ->
      # lane 0 is default
      # lane 0 is outer lane on 4 and 8, but inner lane on 29
      expect(@race.track.radiusOnLane 4, @redLane).to.approximate 110
      expect(@race.track.radiusOnLane 8, @redLane).to.approximate 210
      expect(@race.track.radiusOnLane 29, @redLane).to.approximate 90

      @redLane.add createPosition 4, 0.0, 0, 1, 1
      @redLane.add createPosition 8, 0.0, 0, 1, 1
      @redLane.add createPosition 29, 0.0, 0, 1, 1
      # lane 1 is inner lane on 4 and 8, but outer lane on 29
      expect(@race.track.radiusOnLane 4, @redLane).to.approximate 90
      expect(@race.track.radiusOnLane 8, @redLane).to.approximate 190
      expect(@race.track.radiusOnLane 29, @redLane).to.approximate 110

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
      @redLane = @race.getCarLane 'red'
      @blueLane = @race.getCarLane 'blue'
      expect(@race.getRadiusOnLane(4, @redLane)).to.be 110
      expect(@race.getRadiusOnLane(4, 'red')).to.be 110
      expect(@race.getRadiusOnLane(4, @blueLane)).to.be 90
      expect(@race.getRadiusOnLane(4, 'blue')).to.be 90

    it 'approximates length for switch on straight piece given the lanes', ->
      # from 0 to 1
      @redLane.add createPosition 3, 0.0, 0, 0, 1
      expect(@race.track.pieceLength 3, @redLane).to.approximate 102.060, 0.002
      # from 1 to 0
      @redLane.add createPosition 3, 0.0, 0, 1, 0
      expect(@race.track.pieceLength 3, @redLane).to.approximate 102.060, 0.002

    it 'approximates length for switch on bended piece given the lanes', ->
      # from 0 to 1
      @redLane.add createPosition 8, 0.0, 0, 0, 1
      expect(@race.track.pieceLength 8, @redLane).to.approximate(81.0546, 0.01)

      # from 1 to 0
      @redLane.add createPosition 8, 0.0, 0, 1, 0
      expect(@race.track.pieceLength 8, @redLane).to.approximate(81.0546, 0.01)

      # from 0 to 1
      @redLane.add createPosition 29, 0.0, 0, 0, 1
      expect(@race.track.pieceLength 29, @redLane).to.approximate(81.0294, 0.01)

      # from 1 to 0
      @redLane.add createPosition 29, 0.0, 0, 1, 0
      expect(@race.track.pieceLength 29, @redLane).to.approximate(81.0281, 0.01)

    describe 'basic information for the bot', ->
      createBlueCarPositions = (pieceIndex, inPieceDistance, lap, startLaneIndex, endLaneIndex) ->
        carPositions = objects.clone samplePositions[0]
        carPositions[1].piecePosition = createPosition(pieceIndex, inPieceDistance, lap, startLaneIndex, endLaneIndex)
        carPositions

      @beforeEach ->
        @race.addCarPositions position, tick for position, tick in samplePositions

      it 'provides the current position for a color', ->
        currentPositions = samplePositions[-1..][0]
        currentPositionRed = currentPositions[0]
        expect(@race.getPiecePosition 'red').to.eql currentPositionRed.piecePosition
        expect(@race.getLane 'red').to.eql currentPositionRed.piecePosition.lane
        expect(@race.getCarAngle 'red').to.equal currentPositionRed.angle
        expect(@race.getCarDistance 'red').to.approximate @race.distance currentPositionRed.piecePosition
        expect(@race.getNormalizedPieceIndex 'red').to.eql 0

        currentPiecePositionBlue = currentPositions[1].piecePosition
        initialPiecePositionBlue = samplePositions[0][1].piecePosition
        expect(@race.getCarDistance 'blue').to.approximate @race.distance(currentPiecePositionBlue, initialPiecePositionBlue)
        expect(@race.getLane 'blue').to.eql currentPiecePositionBlue.lane
        expect(@race.getNormalizedPieceIndex 'blue').to.eql -1

      it 'provides the current piece and piece ahead', ->
        expect(@race.getPiece 'red').to.eql sampleRace.track.pieces[0]
        expect(@race.getPieceAhead 'red').to.eql sampleRace.track.pieces[1]
        expect(@race.getPiece 'blue').to.eql sampleRace.track.pieces[39]
        expect(@race.getPieceAhead 'blue').to.eql sampleRace.track.pieces[0]

      it 'provides the correct distance for a car on lane 1', ->
        # piece 4 has length 70.6858 on lane 1
        @race.addCarPositions createBlueCarPositions(4, 62.6858, 0, 1, 1), 498
        @race.addCarPositions createBlueCarPositions(4, 65.6858, 0, 1, 1), 499
        @race.addCarPositions createBlueCarPositions(5, 0.0, 0, 1, 1), 500
        currentPiecePositionBlue = createPosition(5, 0.0, 0, 1, 1)
        initialPiecePositionBlue = samplePositions[0][1].piecePosition
        expect(@race.getCarDistance 'blue').to.approximate @race.distance(currentPiecePositionBlue, initialPiecePositionBlue, @race.getCarLane('blue'))
        expect(@race.getVelocity 'blue', 499).to.approximate 3.0
        expect(@race.getVelocity 'blue').to.approximate 5.0
        expect(@race.getVelocity 'blue', 500, 2).to.approximate 4.0
        expect(@race.getAcceleration 'blue').to.approximate 2.0


      it 'provides the straight distance ahead', ->
        currentPositions = samplePositions[-1..][0]
        currentPositionRed = currentPositions[0].piecePosition

        expect(@race.nextBendedPieceIndex 'red').to.equal 4
        expect(@race.straightDistanceAhead 'red').to.approximate @race.distance(createPosition(4, 0), currentPositionRed)

        # Inside a bended piece
        @race.addCarPositions createBlueCarPositions(4, 10.0, 0, 1, 1), 40
        expect(@race.nextBendedPieceIndex 'blue').to.equal 4
        expect(@race.straightDistanceAhead 'blue').to.equal 0
        expect(@race.straightToFinish 'blue').to.be.false()

        # Test for end of lane
        @race.addCarPositions createBlueCarPositions(35, 0.0, 0, 1, 1), 500
        expect(@race.nextBendedPieceIndex 'blue').to.equal 44
        expect(@race.straightDistanceAhead 'blue').to.equal 890
        expect(@race.straightToFinish 'blue').to.be.false()

        # Second lap
        @race.addCarPositions createBlueCarPositions(75, 0.0, 0, 1, 1), 1000
        expect(@race.straightToFinish 'blue').to.be.false()

        # Third and last lap
        @race.addCarPositions createBlueCarPositions(114, 20.0, 0, 1, 1), 2000
        expect(@race.straightToFinish 'blue').to.be.false()
        @race.addCarPositions createBlueCarPositions(115, 0.0, 0, 1, 1), 2005
        expect(@race.straightToFinish 'blue').to.be.true()


    describe 'velocity and acceleration calculation', ->
      @beforeEach ->
        @race.addCarPositions position, tick for position, tick in samplePositions

      it 'calculates velocity for given tick and number of ticks', ->
        expect(@race.getVelocity 'red', 0).to.approximate 0.0
        expect(@race.getVelocity 'red', 0, 0).to.approximate 0.0
        expect(@race.getVelocity 'red', 1, 0).to.approximate 0.0
        expect(@race.getVelocity 'red', 1).to.approximate 0.126
        expect(@race.getVelocity 'red', 1, 5).to.approximate 0.126
        expect(@race.getVelocity 'red', 5).to.approximate 1.84035 - 1.235051
        expect(@race.getVelocity 'red', 5, 2).to.approximate (1.84035 - 0.7459704) / 2
        expect(@race.getVelocity 'red', 5, 5).to.approximate 1.84035 / 5
        expect(@race.getVelocity 'red', 5, 10).to.approximate 1.84035 / 5
        expect(@race.getVelocity 'blue', 1).to.approximate 0.04
        expect(@race.getVelocity 'blue', 1, 5).to.approximate 0.04
        expect(@race.getVelocity 'blue', 5, 2).to.approximate 0.17371

      it 'calculates velocity for last tick', ->
        lastTick = samplePositions.length - 1
        expect(@race.getVelocity 'red').to.equal @race.getVelocity 'red', lastTick
        expect(@race.getVelocity 'blue').to.equal @race.getVelocity 'blue', lastTick

      it 'calculates acceleration for given tick and number of ticks', ->
        expect(@race.getAcceleration 'red', 0).to.approximate 0.0
        expect(@race.getAcceleration 'red', 1).to.approximate 0.126
        expect(@race.getAcceleration 'red', 1, 5).to.approximate 0.126
        expect(@race.getAcceleration 'red', 5).to.approximate (@race.getVelocity('red', 5) - @race.getVelocity('red', 4))
        expect(@race.getAcceleration 'red', 5, 2).to.approximate (@race.getVelocity('red', 5, 2) - @race.getVelocity('red', 4, 2))
        expect(@race.getAcceleration 'red', 5, 5).to.approximate (@race.getVelocity('red', 5, 5) - @race.getVelocity('red', 4, 5))
        expect(@race.getAcceleration 'red', 5, 10).to.approximate (@race.getVelocity('red', 5, 10) - @race.getVelocity('red', 4, 10))

        expect(@race.getAcceleration 'blue', 1).to.approximate 0.04
        expect(@race.getAcceleration 'blue', 5, 2).to.approximate (@race.getVelocity('blue', 5, 2) - @race.getVelocity('blue', 4, 2))

      it 'calculates acceleration for last tick', ->
        lastTick = samplePositions.length - 1
        expect(@race.getAcceleration 'red').to.equal @race.getAcceleration 'red', lastTick
        expect(@race.getAcceleration 'blue').to.equal @race.getAcceleration 'blue', lastTick

    describe 'max angle', ->
      it 'is 60 by default', ->
        expect(@race.maxAngle).to.equal 60.0

      it 'is set to the last angle before a crash', ->
        positions = samplePositions[0]
        positions[0].angle = 40.0
        positions[1].angle = 45.0
        @race.addCarPositions positions, 20
        @race.addCrash color: 'blue', 21

        expect(@race.maxAngle).to.equal 45.0

