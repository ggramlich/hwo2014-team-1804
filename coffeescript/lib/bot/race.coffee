module.exports = (objects) ->
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

  class Track
    constructor: ({@id, @pieces, lanes}) ->
      @lanes = new Lanes lanes

    normalizedPieceIndex: ({pieceIndex, lap}) =>
      lap * @pieces.length + pieceIndex

    pieceAt: (normalizedIndex) ->
      # positive modulus
      index = ((normalizedIndex % @pieces.length) + @pieces.length) % @pieces.length
      @pieces[index]

    addPiecesLengthsBetween: (initialPosition, piecePosition, carLane) ->
      indices = [(@normalizedPieceIndex initialPosition)...(@normalizedPieceIndex piecePosition)]
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

  class Race
    constructor: ({track, @cars, @raceSession}) ->
      @currentTick = 0
      @track = new Track track
      @carLanes = []
      @carPositions = []
      @carColors = []
      for car in @cars
        color = car.id.color
        @carColors.push color
        @carLanes[color] = @createCarLane()
        @carPositions[color] = new CarPositions

    createCarLane: -> new CarLane @track.normalizedPieceIndex

    distance: (piecePosition, initialPosition = createPosition(0, 0), carLane = @createCarLane()) ->
      if not (carLane instanceof CarLane)
        carLane = @getCarLane carLane
      sum = @track.addPiecesLengthsBetween initialPosition, piecePosition, carLane
      sum + piecePosition.inPieceDistance

    addCarPositions: (carPositions, tick = -1) ->
      @currentTick = tick
      for carPosition in carPositions
        @carLanes[carPosition.id.color].add carPosition.piecePosition
        @carPositions[carPosition.id.color].add tick, carPosition

    getPiecePosition: (color, tick) ->
      @carPositions[color].getPiecePosition tick

    getCarLane: (color) ->
      objects.clone @carLanes[color]

    getVelocity: (color, tick = @currentTick, numberOfTicks = 1) ->
      if tick <= 0 then return 0
      numberOfTicks = Math.min tick, numberOfTicks
      @distance(@getPiecePosition(color, tick), @getPiecePosition(color, tick - numberOfTicks)) / numberOfTicks

    class CarLane
      constructor: (@normalizedPieceIndex) ->
        @laneAtIndex = []
        @lowestIndex = null

      at: (position) -> @atIndex @normalizedPieceIndex position
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
        index = @normalizedPieceIndex position
        if @isLowerThanLowestIndex index
          @lowestIndex = index
        @laneAtIndex[index] = position.lane

    class CarPositions
      constructor: -> @positions = []
      add: (tick, position) -> @positions[tick] = position
      getPiecePosition: (tick) -> @positions[tick].piecePosition

  createPosition = (pieceIndex, inPieceDistance, lap = 0, startLaneIndex = 0, endLaneIndex = startLaneIndex) ->
    lane = {startLaneIndex, endLaneIndex}
    {pieceIndex, inPieceDistance, lane, lap}

  create = (raceData) -> new Race raceData

  return {createPosition, create}