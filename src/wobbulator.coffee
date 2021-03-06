# # How it works: The Wobbulator
#
# The "Wobbulator" was one example of a recycled or salvaged piece of
# equipment put to creative use in the Radiophonic Workshop. The
# Wobbulator was in fact an oscillator (looking at archive pictures
# quite likely a [Brüel & Kjær Beat Frequency Oscillator
# 1022](http://www.radiomuseum.org/r/bruelkjae_beat_frequency_oscillato.html)
# used by sound engineers to measure the acoustic properties of
# studios or by electrical engineers to test equipment.
#
# The large centre knob sets the frequency of a primary oscillator.
# This frequency is then modulated (or "wobbled") a small amount by
# a secondary oscillator. The depth of the wobble is controlled by the
# amplitude of the secondary oscillator, and the frequency of the
# wobble by its frequency.
#
# When the frequencies are in the audible range, the wobbulator can
# produce a wide variety of space-y sounds.
#
# To simulate the wobbulator we use the
# [OscillatorNode](https://webaudio.github.io/web-audio-api/#the-oscillatornode-interface)
# from the Web Audio API.
# We've taken a historical liberty by including a switch to control
# the waveshape of the primary oscillator. While probably not true to
# the original device, the OscillatorNode makes this too hard to
# resist!
#

# # Dependencies
#
# We use [jQuery](http://jquery.com/),
# [backbone.js](http://backbonejs.org/) and some custom UI elements
# (namely a [knob](/docs/knob.html) and a [switch](/docs/switch.html))
# in this application. We make these libraries available to our
# application using [require.js](http://requirejs.org/).
require(["jquery", "backbone", "knob", "switch"], ($, Backbone, Knob, Switch) ->
  $(document).ready ->

    # # ModulatedOscillator
    #
    # This class implements a modulated oscillator. It can be
    # represented as a simple graph. An oscilator (Osc1) is connected
    # to the output (the destination of the
    # [AudioContext](https://webaudio.github.io/web-audio-api/#AudioContext)).
    # A second oscillator (Osc2) is used to modulate the frequency of
    # Osc1.
    #
    # <pre style="font-family:monospace">
    #
    # +--------+      +--------+
    # |        |      |        |
    # |  Osc2  +------>  Gain  |
    # |        |      |        |
    # +---+----+      +---+----+
    #                     | Frequency
    #                 +---v----+        +--------+
    #                 |        |        |        |
    #                 |  Osc1  +--------> Output |
    #                 |        |        |        |
    #                 +--------+        +--------+
    #
    # </pre>
    class ModulatedOscillator
      constructor: (context) ->
        # The primary oscillator.
        @oscillator = context.createOscillator()

        # The modulating oscillator.
        @modulator = context.createOscillator()

        # The amplitude of the modulation oscillator (its 'depth') is
        # modified by passing the output through a GainNode.
        @modulation_gain = context.createGain()

        # Another GainNode controls the master volume.
        @master_gain = context.createGain()

        # Connect the graph as shown above.
        @modulator.connect(@modulation_gain)
        @modulation_gain.connect(@oscillator.frequency)

        @oscillator.connect(@master_gain)
        @master_gain.connect(context.destination)

        # Once an OscillatorNode is stopped it cannot be restarted. We
        # turn both oscillators on from the beginning, and achieve the
        # on/off effect by modifying the master gain.
        @oscillator.start(0)
        @modulator.start(0)

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

      setAudioWaveform: (value) ->
        @oscillator.type = value

      on: ->
        @turned_on = true
        @master_gain.gain.value = 1

      off: ->
        @turned_on = false
        @master_gain.gain.value = 0

    # # Initial parameters
    context = new AudioContext
    oscillator = new ModulatedOscillator(context)

    # Set the initial parameters of the oscillator.
    initialFrequency = 440
    initialModulationDepth = 100
    initialModulationFrequency = 10

    oscillator.setFrequency(initialFrequency)
    oscillator.setModulationDepth(initialModulationDepth)
    oscillator.setModulationFrequency(initialModulationFrequency)

    oscillator.off()

    # # User Interface code
    #
    # We create an on/off [switch](/docs/switch.html) and three
    # [knobs](/docs/knob.html) to set each of the parameters of the
    # `ModulatedOscillator`. We bind these UI elements to `div`s in the
    # HTML.
    on_off_switch = new Switch(el: '#switch')

    audio_waveform_switch = new Switch(
      el: '#audio-waveform'
      states: ['sine', 'square', 'sawtooth']
    )

    frequency_knob = new Knob(
      el: '#frequency'
      degMin: -53
      degMax: 227
      valueMin: 50
      valueMax: 5000
      initial_value: initialFrequency
    )

    modulation_frequency_knob = new Knob(
      el: '#modulation-frequency'
      valueMin: 0
      valueMax: 50
      initial_value: initialModulationFrequency
    )

    modulation_depth_knob = new Knob(
      el: '#modulation-depth'
      valueMin: 0
      valueMax: 200
      initial_value: initialModulationDepth
    )

    volume_knob = new Knob(
      el: '#volume'
      initial_value: 1
    )

    # Events are fired when each of the knob values change. We map
    # these events to parameters of the `ModulatedOscillator`.
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

    audio_waveform_switch.on('all', (e)->
      oscillator.setAudioWaveform(e)
    )
)
