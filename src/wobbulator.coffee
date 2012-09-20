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
      alert 'Your browser does not support the Web Audio API'

    # # ModulatedOscillator
    #
    # This class implements a modulated oscillator. It can be
    # represented as a simple graph. An oscilator (Osc2) is connected
    # to the destination of the audioContext. A second oscillator
    # (Osc1) is used to modulate the frequency of Osc1.
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

      setFrequency: (value) ->
        @oscillator.frequency.value = value

      setModulationAmplitude: (value) ->
        @modulation_gain.gain.value = value

      setModulationFrequency: (value) ->
        @modulator.frequency.value = value

      setMasterGain: (value) ->
        @master_gain.gain.value = value

      on: ->
        this.setMasterGain(1)

      off: ->
        this.setMasterGain(0)

    # # Main application
    audioContext = new webkitAudioContext
    oscillator = new ModulatedOscillator(audioContext)

    # Set the initial parameters of the oscillator
    initialFrequency = 440

    oscillator.setFrequency(initialFrequency)
    oscillator.setModulationAmplitude(10)
    oscillator.setModulationFrequency(5)
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
      initial_value: (initialFrequency-50) / (5000-50)
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
      (v) -> oscillator.setFrequency( (5000-50) * v + 50 ))

    modulation_frequency_knob.on('valueChanged',
      (v) -> oscillator.setModulationFrequency(50 * v))

    modulation_depth_knob.on('valueChanged',
      (v) -> oscillator.setModulationAmplitude(50 * v))

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
