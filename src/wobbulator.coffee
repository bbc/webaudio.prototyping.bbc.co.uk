# # The Wobbulator
#
# The "Wobbulator" was one example of a recycled or salvaged piece of
# equipment put to creative use at the Radiophonic Workshop. The
# Wobbulator was in fact a beat-frequency oscillator (looking at
# archive pictures quite likely a [Brüel & Kjær Beat Frequency
# Oscillator
# 1022](http://www.radiomuseum.org/r/bruelkjae_beat_frequency_oscillato.html)
# or similar) used by sound engineers to measure the acoustic
# properties of studios or by electrical engineers to test equipment.
# When the frequencies are lowered to the audible range, it can
# produce a wide variety of space-y sounds.
#
# This application is a simulation of the Wobbulator using the Web
# Audio API.

# # Preamble
#
# We use jQuery, backbone.js and some custom UI elements (namely a
# [knob](views/knob.html) and a [switch](views/switch.html)) in this
# application. We make these libraries available to our application
# using [require.js](http://requirejs.org/)
require(["jquery", "backbone", "knob", "switch"], ($, Backbone, KnobView, SwitchView) ->
  $(document).ready ->
    # We need to alert the user if the Web Audio API is not available.
    # Testing for the existence of `webkitAudioContext` is currently
    # a good way to achieve that.
    if typeof(webkitAudioContext) == 'undefined' && typeof(AudioContext) == 'undefined'
      alert 'Your browser does not support the Web Audio API. Try Google Chrome or a Webkit nightly build'


    # # Oscillator
    #
    # This is our principle oscillator node. It
    # implements a frequency-modulated sine-wave oscillator where the
    # primary frequency, the modulation frequency and the modulation
    # depth are controllable parameters. At the time of writing the "native"
    # [Oscillator
    # interface](https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#Oscillator)
    # is not available in any stable version of Webkit, so we use a
    # [JavaScript
    # node](https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#JavaScriptAudioNode)
    # instead.
    class ModulatedOscillator
      constructor: (@context) ->
        # Our node has 0 inputs and 1 output and processes 1024
        # samples at a time. The `process` callback is fired every
        # 1024 samples
        @node = @context.createJavaScriptNode(1024, 2, 2)
        @node.onaudioprocess = (e) => @process(e)

        @phase = 0
        @modulation_phase = 0
        @modulation_frequency = 5
        @frequency = 440
        @modulation_depth = 10
        @sample_rate = context.sampleRate
        @amplitude = 0.5

      process: (e) ->
        # We want to generate stereo output, so we assign the
        # generated samples on both the left(0) and right(1) channels
        data_l = e.outputBuffer.getChannelData(0)
        data_r = e.outputBuffer.getChannelData(1)

        # Each time the process call back is called we have 1024
        # samples to populate. We are implementing the FM equation:
        #
        # `y = cos( 2πft + ßsin(2πfmt) )`
        #
        # where `f` is the frequency, `ß` the modulation depth, `fm`
        # the modulation frequency and `t` the time.
        #
        # We accumulate the changes in phase in two instance variables
        # `modulation_phase` and `phase` so that they carry over each
        # time the callback is called. This prevents audible
        # 'glitching'.
        for i in [0..data_l.length-1]
          sample_i = @amplitude * Math.cos(@phase + (@modulation_depth * Math.sin(@modulation_phase)))

          data_l[i] = sample_i
          data_r[i] = sample_i

          @modulation_phase = @modulation_phase + ((2 * Math.PI * @modulation_frequency) / @sample_rate)
          @phase = @phase + ((2 * Math.PI * @frequency) / @sample_rate)

      # Turning the oscillator on and off can be achieved simply in
      # this case by connecting and disconnecting the audio node from
      # the destination
      on: ->
        @node.connect(@context.destination)

      off: ->
        @node.disconnect()

    # # Main application

    # Our application is a simple graph: a JavaScript node connected
    # to the destination.
    #
    # <pre style="font-family:monospace">
    #  +-------------+         +-------------+
    #  |             |         |             |
    #  |             |         |             |
    #  |   JS Node   |-------->| Destination |
    #  |             |         |             |
    #  |             |         |             |
    #  +-------------+         +-------------+
    # </pre>
    audioContext = new webkitAudioContext
    oscillator = new ModulatedOscillator(audioContext)

    # # UI code
    #
    # We create an on/off switch and three knobs to control each of
    # the parameters of the `ModulatedOscillator`. We bind these UI
    # elements to divs in the markup
    on_off_switch = new SwitchView(el: '#switch')

    frequency_knob = new KnobView(
      el: '#frequency'
      degMin: -53
      degMax: 227
      initial_value: (440-50) / (5000-50)
    )

    modulation_frequency_knob = new KnobView(
      el: '#modulation-frequency'
      initial_value: 0.5 / 50
    )

    modulation_depth_knob = new KnobView(
      el: '#modulation-depth'
      initial_value: 0.5 / 50
    )

    volume_knob = new KnobView(
      el: '#volume'
    )

    # Register events to be fired when each of the knob values change.
    # One for each parameter of the `ModulatedOscillator`
    frequency_knob.on('valueChanged',
      (v) -> oscillator.frequency = (5000-50) * v + 50)

    modulation_frequency_knob.on('valueChanged',
      (v) -> oscillator.modulation_frequency = 50 * v)

    modulation_depth_knob.on('valueChanged',
      (v) -> oscillator.modulation_depth = 50 * v)

    volume_knob.on('valueChanged',
      (v) -> oscillator.amplitude = v)

    # Register on/off events to be fired when the switch is toggled.
    on_off_switch.on('on', ->
      oscillator.on()
      $('#bulb').removeClass('off').addClass('on')
    )

    on_off_switch.on('off', ->
      oscillator.off()
      $('#bulb').removeClass('on').addClass('off')
    )
)
