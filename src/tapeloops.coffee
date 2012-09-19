# # Tape Loops
#
# In the early days of the Radiophonics Workshop pieces of music were
# painstakingly composed a note at a time by recording and splicing
# together pieces of tapes in loops. In [this
# video](http://www.youtube.com/watch?v=NDX_CS3NsTk) you can see Delia
# Derbyshire explaining the process and showing one of the more tricky
# aspects - that of "beat matching" the individual loops so that they
# are in sync.
#
# ![Tape machine](img/tapemachine.jpg "A photo of a tapemachine from the Science Museum Oramics Exhibit")
#
# This application is a simulation of three tape loop machines with
# variable speed controls using the Web Audio API.

# # Preamble
#
# We use jQuery, backbone.js and some custom UI elements (namely a
# [knob](views/knob.html) and a [switch](views/switch.html)) in this
# application. We make these libraries available to our application
# using [require.js](http://requirejs.org/)
require(["jquery", "backbone", "knob", "switch"], ($, Backbone, KnobView, SwitchView) ->
  $(document).ready ->
    if typeof(webkitAudioContext) == 'undefined' && typeof(AudioContext) == 'undefined'
      alert 'Your browser does not support the Web Audio API. Try Google Chrome or a Webkit nightly build'

    # Create an audio context for our application to exist within.
    audioContext = new webkitAudioContext

    # # Player
    #
    # This class implements a sample player. The player wraps
    # an `audioBufferSource` node with the sample data loaded using an
    # AJAX request
    class Player
      constructor: (@url) ->
        this.loadBuffer()
        # Multiplications for base speed and fine speed controls
        this.setBaseSpeed(1)
        this.setSpeedFine(1)

      play: ->
        if @buffer
          # Sample playback in the Web Audio API is achieved by
          # setting buffer to the contents of the sound each time the
          # sample is played.
          @source = audioContext.createBufferSource()
          @source.buffer = @buffer
          @source.connect audioContext.destination
          @source.loop = true
          this.setSpeed()
          # Trigger the source to play immediately
          @source.noteOn 0

      stop: ->
        if @buffer && @source
          # Stop the sample playback immediately
          @source.noteOff 0

      setBaseSpeed: (speed) ->
        @base_speed = speed
        this.setSpeed()

      setSpeedFine: (speed) ->
        @fine_speed = speed
        this.setSpeed()

      # The playback speed is a combination of the "base speed"
      # (normal or double speed playback) and a "fine speed" control.
      setSpeed: ->
        if @source
          @source.playbackRate.value = @base_speed * @fine_speed

      loadBuffer: ->
        self = this

        request = new XMLHttpRequest()
        request.open('GET', @url, true)
        request.responseType = 'arraybuffer'

        # Load the decoded sample into the buffer if the request is successful
        request.onload = =>
          onsuccess = (buffer) ->
            self.buffer = buffer

          onerror = -> alert "Could not load #{@url}"

          audioContext.decodeAudioData request.response, onsuccess, onerror

        request.send()

    # # MachineView
    #
    # This class wraps the various user interface
    # elements to make it easy to create an instance per tape machine.
    class MachineView
      constructor: (@el, @player) ->
        @setupDoubleSpeed()
        @setupFineSpeed()
        @setupPlayStop()

      # The double speed control sets the base speed of the player to
      # 2 when toggled.
      setupDoubleSpeed: () ->
        double_speed_control = new SwitchView( el: $(@el).find('.double-speed') )
        # [SwitchView's](views/switch.html) trigger custom `on` and `off` events. We bind
        # these events to the `setBaseSpeed` method of the player.
        double_speed_control.on('on', => @player.setBaseSpeed(2))
        double_speed_control.on('off', => @player.setBaseSpeed(1))

      # Attach a knob to the fine speed control to vary the playback
      # speed by ± 3%
      setupFineSpeed: () ->
        fine_speed_control = new KnobView(
          el: $(@el).find('.fine-speed')
        )

        # The [KnobView](views/knob.html) triggers `valueChanged` events in the range
        # [0,1] when turned. We scale these to ±3% and bind them to
        # the `setSpeedFine` method on the player
        fine_speed_control.on('valueChanged', (v) =>
          speed = v * (1.03 - 0.97) + 0.97
          @player.setSpeedFine(speed)
        )

      # A simple switch toggles
      setupPlayStop: () ->
        play_stop_control = new SwitchView(el: $(@el).find('.play'))
        play_stop_control.on('on', => @player.play())
        play_stop_control.on('off', => @player.stop())

    # # Application Setup

    # Instantiate three separate players with the three loops.
    player1 = new Player('/audio/delia_loop_01.ogg')
    player2 = new Player('/audio/delia_loop_02.ogg')
    player3 = new Player('/audio/delia_loop_03.ogg')

    # Setup the Views
    machine1_view = new MachineView('#machine1', player1)
    machine2_view = new MachineView('#machine2', player2)
    machine3_view = new MachineView('#machine3', player3)
)
