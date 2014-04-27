module.exports = (objects) ->
  mod = (n, m) -> ((n % m) + m) % m

  ##################################
  # Race
  ##################################
  class Race
    race = null
    constructor: ({track, @cars, @raceSession}) ->
      race = this
      @currentTick = 0
      @track = new Track track
      @carLanes = []
      @carPositions = []
      @carColors = []
      @maxAngle = 60.0
      for car in @cars
        color = car.id.color
        @carColors.push color
        @carLanes[color] = new CarLane
        @carPositions[color] = new CarPositions

    normalizedPieceIndex: ({pieceIndex, lap}) => lap * @track.pieces.length + pieceIndex
    createPositionForNormalizedIndex: (normalizedIndex) -> createPosition(mod(normalizedIndex, @track.pieces.length), 0, Math.floor(normalizedIndex / @track.pieces.length))

    distance: (piecePosition, initialPosition = createPosition(0, 0), carLane = new CarLane) ->
      if not (carLane instanceof CarLane)
        carLane = @getCarLane carLane
      sum = @track.addPiecesLengthsBetween initialPosition, piecePosition, carLane
      sum + piecePosition.inPieceDistance

    addCarPositions: (carPositions, tick = -1) ->
      @currentTick = tick
      for carPosition in carPositions
        @carLanes[carPosition.id.color].add carPosition.piecePosition
        @carPositions[carPosition.id.color].add tick, carPosition

    getNormalizedPieceIndex: (color, tick = @currentTick) -> @normalizedPieceIndex(@getPiecePosition(color, tick))
    getPieceAt: (normalizedIndex) -> @track.pieceAt(normalizedIndex)
    getPiece: (color, offset = 0) -> @getPieceAt(@getNormalizedPieceIndex(color) + offset)
    getPieceAhead: (color) -> @getPiece(color, 1)
    getPiecePosition: (color, tick = @currentTick) -> @carPositions[color].getPiecePosition tick
    getLane: (color, tick = @currentTick) -> @carLanes[color].at @getPiecePosition color, tick
    getCarDistance: (color, tick = @currentTick) -> @distance @getPiecePosition(color, tick), @getPiecePosition(color, 0), @getCarLane(color)
    straightDistanceAhead: (color, tick = @currentTick) -> Math.max 0, @distance(@nextBendedPiecePosition(color, tick), @getPiecePosition(color, tick))
    nextBendedPiecePosition: (color, tick = @currentTick) -> @createPositionForNormalizedIndex(@nextBendedPieceIndex(color, tick))
    nextBendedPieceIndex: (color, tick = @currentTick) -> @track.nextBendedPieceIndex @getNormalizedPieceIndex(color, tick)
    straightToFinish: (color, tick = @currentTick) -> @track.straightToFinish @getNormalizedPieceIndex(color, tick), @raceSession.laps

    getCarAngle: (color, tick = @currentTick) -> @carPositions[color].getAngle(tick)
    getAngularSpeed: (color, tick = @currentTick) -> @getCarAngle(color, tick) - @getCarAngle(color, tick - 1)
    getAngularSpeedChange: (color, tick = @currentTick) -> @getAngularSpeed(color, tick) - @getAngularSpeed(color, tick - 1)

    getCarLane: (color) -> objects.clone @carLanes[color]

    getVelocity: (color, tick = @currentTick, numberOfTicks = 1) ->
      if tick <= 0 or numberOfTicks <= 0 then return 0
      numberOfTicks = Math.min tick, numberOfTicks
      @distance(@getPiecePosition(color, tick), @getPiecePosition(color, tick - numberOfTicks), @getCarLane color) / numberOfTicks

    getAcceleration: (color, tick = @currentTick, numberOfTicks = 1) ->
      @getVelocity(color, tick, numberOfTicks) - @getVelocity(color, tick - 1, numberOfTicks)

    addCrash: ({color}, tick = @currentTick) ->
      # try to be on the safe side, actually we might want to increase the maxAngle seen so far
      lastAngle = @getCarAngle color, tick - 1
      if lastAngle < @maxAngle
        @maxAngle = lastAngle

    ##################################
    # Track
    ##################################
    class Track
      constructor: ({@id, @pieces, lanes}) ->
        @lanes = new Lanes lanes

      pieceAt: (normalizedIndex) -> @pieces[mod normalizedIndex, @pieces.length]

      addPiecesLengthsBetween: (initialPosition, piecePosition, carLane) ->
        indices = [(race.normalizedPieceIndex initialPosition)...(race.normalizedPieceIndex piecePosition)]
        indices.reduce ((sum, index) => sum + @pieceLength index, carLane), -initialPosition.inPieceDistance

      pieceLength: (index, carLane) ->
        {startDistance, endDistance, totalDistance, isSwitch} = @lanes.getDistances carLane.atIndex index
        piece = @pieceAt(index)
        if (piece.length?)
          if isSwitch
            1.0008 * Math.sqrt totalDistance * totalDistance + piece.length * piece.length
          else
            piece.length
        else
          lengthOnStartLane = @bendedPieceLength piece, startDistance
          return lengthOnStartLane unless isSwitch
          lengthOnEndLane = @bendedPieceLength piece, endDistance
          innerLength = Math.min(lengthOnEndLane, lengthOnStartLane)
          outerLength = Math.max(lengthOnEndLane, lengthOnStartLane)
          ratio = (outerLength / innerLength)
          factor = 1.023 / Math.pow(ratio, 2.2)
          innerLength + (outerLength - innerLength) * factor

      bendedPieceLength: ({radius, angle}, distanceFromCenter) ->
        bended = if angle < 0 then 1 else -1
        laneRadius = radius + bended * distanceFromCenter
        laneRadius * Math.PI * Math.abs(angle) / 180

      nextBendedPieceIndex: (index) ->
        loop
          piece = @pieceAt(index)
          break unless (piece.length?)
          index++
        index

      straightToFinish: (index, laps) ->
        for i in [laps * @pieces.length..index] by -1
          return no unless @pieceAt(i).length?
        yes

    ##################################
    # Lanes
    ##################################
    class Lanes
      constructor: (lanes) ->
        @distanceFromCenter = []
        for lane in lanes
          @distanceFromCenter[lane.index] = lane.distanceFromCenter

      getDistances: ({startLaneIndex, endLaneIndex}) ->
        startDistance = @distanceFromCenter[startLaneIndex]
        endDistance = @distanceFromCenter[endLaneIndex]

        startDistance: startDistance
        endDistance: endDistance
        totalDistance: Math.abs startDistance - endDistance
        isSwitch: startLaneIndex isnt endLaneIndex


    ##################################
    # CarLane
    ##################################
    class CarLane
      constructor: () ->
        @laneAtIndex = []
        @lowestIndex = null

      at: (position) -> @atIndex race.normalizedPieceIndex position
      isLowerThanLowestIndex: (index) -> not @lowestIndex? or index < @lowestIndex

      atIndex: (index) ->
        if @isLowerThanLowestIndex index
          startLaneIndex: 0, endLaneIndex: 0
        else if @laneAtIndex[index]?
          @laneAtIndex[index]
        else
          for i in [index..@lowestIndex] by -1
            if @laneAtIndex[i]?
              endLane = @laneAtIndex[i].endLaneIndex
              return startLaneIndex: endLane, endLaneIndex: endLane

      add: (position) ->
        index = race.normalizedPieceIndex position
        if @isLowerThanLowestIndex index
          @lowestIndex = index
        @laneAtIndex[index] = position.lane


    ##################################
    # CarPositions
    ##################################
    class CarPositions
      constructor: -> @positions = []
      add: (tick, position) -> @positions[tick] = position
      getPiecePosition: (tick) -> @positions[tick]?.piecePosition

      getAngle: (tick) -> @positions[tick]?.angle ? 0



  ##################################
  # To be exported
  ##################################

  createPosition = (pieceIndex, inPieceDistance, lap = 0, startLaneIndex = 0, endLaneIndex = startLaneIndex) ->
    lane = {startLaneIndex, endLaneIndex}
    {pieceIndex, inPieceDistance, lane, lap}

  create = (raceData) -> new Race raceData

  return {createPosition, create}