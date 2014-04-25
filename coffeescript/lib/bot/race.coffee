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

    addPiecesLengthsBetween: (initialPosition, piecePosition) ->
      indices = [(@normalizedPieceIndex initialPosition)...(@normalizedPieceIndex piecePosition)]
      indices.reduce ((sum, index) => sum + @pieceAt(index).length), -initialPosition.inPieceDistance

  class Race
    constructor: ({track, @cars, @raceSession}) ->
      race = this
      @track = new Track track
      @carLanes = []
      for car in @cars
        @carLanes[car.id.color] = new CarLane @track.normalizedPieceIndex

    distance: (piecePosition, initialPosition = createPosition(0, 0)) ->
      sum = @track.addPiecesLengthsBetween initialPosition, piecePosition
      sum + piecePosition.inPieceDistance

    addCarPositions: (carPositions) ->
      for carPosition in carPositions
        @carLanes[carPosition.id.color].add(carPosition.piecePosition)

    getCarLanes: (color) ->
      objects.clone @carLanes[color]

    class CarLane
      constructor: (@normalizedPieceIndex) ->
        @laneAtIndex = []
        @lowestIndex = null

      at: (position) ->
        index = @normalizedPieceIndex position
        if @isNewLowestIndex index
          return startLaneIndex: 0, endLaneIndex: 0
        if @laneAtIndex[index]?
          return @laneAtIndex[index]
        for i in [index..@lowestIndex] by -1
          if @laneAtIndex[i]?
            endLane = @laneAtIndex[i].endLaneIndex
            return startLaneIndex: endLane, endLaneIndex: endLane

      add: (position) ->
        index = @normalizedPieceIndex position
        if @isNewLowestIndex index
          @lowestIndex = index
        @laneAtIndex[index] = position.lane

      isNewLowestIndex: (index) ->
        not @lowestIndex? or index < @lowestIndex

  createPosition = (pieceIndex, inPieceDistance, lap = 0, startLaneIndex = 0, endLaneIndex = startLaneIndex) ->
    lane = {startLaneIndex, endLaneIndex}
    {pieceIndex, inPieceDistance, lane, lap}

  create = (raceData) -> new Race raceData

  return {createPosition, create}