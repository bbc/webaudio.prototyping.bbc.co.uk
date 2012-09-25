# # The Wobbulator
#
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
      alert 'Your browser does not support the Web Audio API'

    # # ModulatedOscillator
    #
    # This class implements a modulated oscillator. It can be
    # represented as a simple graph. An oscilator (Osc2) is connected
    # to the destination of the audioContext. A second oscillator
    # (Osc1) is used to modulate the frequency of Osc2.
    #
    # <pre style="font-family:monospace">
    #
    # +--------+      +--------+
    # |        |      |        |
    # |  Osc1  +------>  Gain  |
    # |        |      |        |
    # +---+----+      +---+----+
    #                     | Frequency
    #                 +---v----+        +--------+
    #                 |        |        |        |
    #                 |  Osc2  +--------> Output |
    #                 |        |        |        |
    #                 +--------+        +--------+
    #
    # </pre>
    class ModulatedOscillator
      constructor: (context) ->
        @oscillator = context.createOscillator()
        @modulator = context.createOscillator()
        @modulation_gain = context.createGainNode()
        @master_gain = context.createGainNode()

        @modulator.connect(@modulation_gain)
        @modulation_gain.connect(@oscillator.frequency)

        @oscillator.connect(@master_gain)
        @master_gain.connect(context.destination)

        @oscillator.noteOn(0)
        @modulator.noteOn(0)

        @turned_on = true

      setFrequency: (value) ->
        @oscillator.frequency.value = value

      setModulationDepth: (value) ->
        @modulation_gain.gain.value = value

      setModulationFrequency: (value) ->
        @modulator.frequency.value = value

      setMasterGain: (value) ->
        @gain = value
        @master_gain.gain.value = @gain if @turned_on

      on: ->
        @turned_on = true
        @master_gain.gain.value = 1

      off: ->
        @turned_on = false
        @master_gain.gain.value = 0

    # # Main application
    audioContext = new webkitAudioContext
    oscillator = new ModulatedOscillator(audioContext)

    # Set the initial parameters of the oscillator
    initialFrequency = 440
    initialModulationDepth = 100
    initialModulationFrequency = 10

    oscillator.setFrequency(initialFrequency)
    oscillator.setModulationDepth(initialModulationDepth)
    oscillator.setModulationFrequency(initialModulationFrequency)

    oscillator.off()

    # # UI code
    #
    # We create an on/off switch and three knobs to set each of
    # the parameters of the `ModulatedOscillator`. We bind these UI
    # elements to divs in the markup
    on_off_switch = new SwitchView(el: '#switch')

    frequency_knob = new KnobView(
      el: '#frequency'
      degMin: -53
      degMax: 227
      valueMin: 50
      valueMax: 5000
      initial_value: initialFrequency
    )

    modulation_frequency_knob = new KnobView(
      el: '#modulation-frequency'
      valueMin: 0
      valueMax: 50
      initial_value: initialModulationFrequency
    )

    modulation_depth_knob = new KnobView(
      el: '#modulation-depth'
      valueMin: 0
      valueMax: 200
      initial_value: initialModulationDepth
    )

    volume_knob = new KnobView(
      el: '#volume'
      initial_value: 1
    )

    # Register events to be fired when each of the knob values change.
    # One for each parameter of the `ModulatedOscillator`
    frequency_knob.on('valueChanged',
      (v) -> oscillator.setFrequency(v))

    modulation_frequency_knob.on('valueChanged',
      (v) -> oscillator.setModulationFrequency(v))

    modulation_depth_knob.on('valueChanged',
      (v) -> oscillator.setModulationDepth(v))

    volume_knob.on('valueChanged',
      (v) -> oscillator.setMasterGain(v))

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
