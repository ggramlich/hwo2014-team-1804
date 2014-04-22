module.exports = ->
  createPosition = (pieceIndex, inPieceDistance, lap = 0, startLaneIndex = 0, endLaneIndex = startLaneIndex) ->
    lane = {startLaneIndex, endLaneIndex}
    {pieceIndex, inPieceDistance, lane, lap}

  class Lanes
    constructor: (lanes) ->
      @distanceFromCenter = []
      for lane in lanes
        @distanceFromCenter[lane.index] = lane.distanceFromCenter

  class Track
    constructor: ({@id, @pieces, lanes}) ->
      @lanes = new Lanes lanes

    normalizedPieceIndex: ({pieceIndex, lap}) ->
      lap * @pieces.length + pieceIndex

    pieceAt: (normalizedIndex) ->
      index = ((normalizedIndex % @pieces.length) + @pieces.length) % @pieces.length
      @pieces[index]

    addPiecesLengthsBetween: (initialPosition, piecePosition) ->
      indices = [(@normalizedPieceIndex initialPosition)...(@normalizedPieceIndex piecePosition)]
      indices.reduce ((sum, index) => sum + @pieceAt(index).length), -initialPosition.inPieceDistance

  class Race
    constructor: ({track, @cars, @raceSession}) ->
      @track = new Track track

    distance: (piecePosition, initialPosition = createPosition(0, 0)) ->
      sum = @track.addPiecesLengthsBetween initialPosition, piecePosition
      sum + piecePosition.inPieceDistance

  createPosition: createPosition
  create: (raceData) -> new Race raceData
