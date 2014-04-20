module.exports =
  track:
    id: "indianapolis"
    name: "Indianapolis"
    pieces: [
      {
        length: 100.0
      }
      {
        length: 100.0
        switch: true
      }
      {
        radius: 200
        angle: 22.5
      }
    ]
    lanes: [
      {
        distanceFromCenter: -20
        index: 0
      }
      {
        distanceFromCenter: 0
        index: 1
      }
      {
        distanceFromCenter: 20
        index: 2
      }
    ]
    startingPoint:
      position:
        x: -340.0
        y: -96.0

      angle: 90.0

  cars: [
    {
      id:
        name: "Schumacher"
        color: "red"

      dimensions:
        length: 40.0
        width: 20.0
        guideFlagPosition: 10.0
    }
    {
      id:
        name: "Rosberg"
        color: "blue"

      dimensions:
        length: 40.0
        width: 20.0
        guideFlagPosition: 10.0
    }
  ]
  raceSession:
    laps: 3
    maxLapTimeMs: 30000
    quickRace: true
