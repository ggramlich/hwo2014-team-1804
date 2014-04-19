module.exports =
  class Bot
    constructor: ({@name, @color}) ->
      if @color is 'red'
        @throttle = 0.602
      else
        @throttle = 0.64
    carPositions: (data, control) ->
      console.log "Bot #{@color}"
      if data.gameTick is 65
        if @color is 'red'
          control.switchLane 'Right'
        else
          control.switchLane 'Left'
      else
        control.throttle @throttle
