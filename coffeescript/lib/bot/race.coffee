module.exports = ->
  class Lanes
    constructor: (lanes) ->
      @distanceFromCenter = []
      for lane in lanes
        @distanceFromCenter[lane.index] = lane.distanceFromCenter

  class Track
    constructor: ({@id, @pieces, lanes}) ->
      @lanes = new Lanes lanes

  class Race
    constructor: ({track, @cars, @raceSession}) ->
      @track = new Track track
#      console.log @track
#      console.log @cars
#      console.log @raceSession

  create: (raceData) -> new Race raceData
