module.exports =
  track:
    id: "keimola"
    name: "Keimola"
    pieces: [
      {
        length: 100
      }
      {
        length: 100
      }
      {
        length: 100
      }
      {
        length: 100
        switch: true
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 200
        angle: 22.5
        switch: true
      }
      {
        length: 100
      }
      {
        length: 100
      }
      {
        radius: 200
        angle: -22.5
      }
      {
        length: 100
      }
      {
        length: 100
        switch: true
      }
      {
        radius: 100
        angle: -45
      }
      {
        radius: 100
        angle: -45
      }
      {
        radius: 100
        angle: -45
      }
      {
        radius: 100
        angle: -45
      }
      {
        length: 100
        switch: true
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 200
        angle: 22.5
      }
      {
        radius: 200
        angle: -22.5
      }
      {
        length: 100
        switch: true
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        length: 62
      }
      {
        radius: 100
        angle: -45
        switch: true
      }
      {
        radius: 100
        angle: -45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        radius: 100
        angle: 45
      }
      {
        length: 100
        switch: true
      }
      {
        length: 100
      }
      {
        length: 100
      }
      {
        length: 100
      }
      {
        length: 90
      }
    ]
    lanes: [
      {
        distanceFromCenter: -10
        index: 0
      }
      {
        distanceFromCenter: 10
        index: 1
      }
    ]
    startingPoint:
      position:
        x: -300
        y: -44

      angle: 90

  cars: [
    {
      id:
        name: "ggramlich"
        color: "red"

      dimensions:
        length: 40
        width: 20
        guideFlagPosition: 10
    }
    {
      id:
        name: "ggramlich1"
        color: "blue"

      dimensions:
        length: 40
        width: 20
        guideFlagPosition: 10
    }
  ]
  raceSession:
    laps: 3
    maxLapTimeMs: 60000
    quickRace: true
