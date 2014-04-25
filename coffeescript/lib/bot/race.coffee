module.exports = (objects) ->
  class Lanes
    constructor: (lanes) ->
      @distanceFromCenter = []
      for lane in lanes
        @distanceFromCenter[lane.index] = lane.distanceFromCenter

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
      piece = @pieceAt(index)
      if (piece.length?)
        piece.length
      else
        {radius, angle} = piece
        bended = if angle < 0 then 1 else -1
        {startLaneIndex, endLaneIndex} = carLane.atIndex index
        laneRadius = radius + bended * @lanes.distanceFromCenter[endLaneIndex]
        laneRadius * Math.PI * Math.abs(angle) / 180

  class Race
    constructor: ({track, @cars, @raceSession}) ->
      @track = new Track track
      @carLanes = []
      for car in @cars
        @carLanes[car.id.color] = @createCarLane()

    createCarLane: -> new CarLane @track.normalizedPieceIndex

    distance: (piecePosition, initialPosition = createPosition(0, 0), carLane = @createCarLane()) ->
      if not (carLane instanceof CarLane)
        carLane = @getCarLane carLane
      sum = @track.addPiecesLengthsBetween initialPosition, piecePosition, carLane
      sum + piecePosition.inPieceDistance

    addCarPositions: (carPositions) ->
      for carPosition in carPositions
        @carLanes[carPosition.id.color].add(carPosition.piecePosition)

    getCarLane: (color) ->
      objects.clone @carLanes[color]

    class CarLane
      constructor: (@normalizedPieceIndex) ->
        @laneAtIndex = []
        @lowestIndex = null

      at: (position) ->
        index = @normalizedPieceIndex position
        @atIndex index

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

      isLowerThanLowestIndex: (index) ->
        not @lowestIndex? or index < @lowestIndex

  createPosition = (pieceIndex, inPieceDistance, lap = 0, startLaneIndex = 0, endLaneIndex = startLaneIndex) ->
    lane = {startLaneIndex, endLaneIndex}
    {pieceIndex, inPieceDistance, lane, lap}

  create = (raceData) -> new Race raceData

  return {createPosition, create}