race = require('../../lib/bot/race')()
expect = require('chai').expect

describe 'Race distance calculation', ->
  before ->
    @race = race.create require './samplerace'

  it 'results in 0 for beginning of first piece', ->
    piecePosition =
      pieceIndex: 0
      inPieceDistance: 0.0
      lane:
        startLaneIndex: 0
        endLaneIndex: 0
      lap: 0

    expect(@race.distance piecePosition).to.equal 0.0

