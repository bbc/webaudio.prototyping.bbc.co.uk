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

    class WhiteNoise
      constructor: (context) ->
        self = this
        @context = context
        @node = @context.createJavaScriptNode(1024, 1, 2)
        @node.onaudioprocess = (e) -> self.process(e)

      process: (e) ->
        data0 = e.outputBuffer.getChannelData(0)
        data1 = e.outputBuffer.getChannelData(1)
        for i in [0..data0.length-1]
          data0[i] = ((Math.random() * 2) - 1)
          data1[i] = data0[i]


     class Filter
      constructor: (context) ->
        self = this
        @context = context
        @node = @context.createBiquadFilter()
        @node.type = 0
        @node.Q.value = 10
        @node.frequency.value = 800

      setFrequency: (frequency)->
        @node.frequency.value = frequency

    class Envelope
      constructor: (context) ->
        self = this
        @context = context
        @node = @context.createGainNode()
        @node.gain.value = 0

      impulse: ->
        @node.gain.linearRampToValueAtTime(0, @context.currentTime);
        @node.gain.linearRampToValueAtTime(1, @context.currentTime + 0.001);
        @node.gain.linearRampToValueAtTime(0.3, @context.currentTime + 0.101);
        @node.gain.linearRampToValueAtTime(0, @context.currentTime + 0.300);

    class ControlView extends Backbone.View
      el: $("#controls")

      initialize: (filter,envelope,gainDry,gainWet,audioContext) ->
        @filter = filter
        @envelope = envelope
        @gainDry = gainDry
        @gainWet = gainWet
        @audioContext = audioContext

       events:
         "click #fire": "fire"
         "change #levelDry": "changeLevelDry"
         "change #levelWet": "changeLevelWet"
         "change #distance": "changeDistance"

       fire: ->
         @envelope.impulse()

       changeLevelDry: ->
         @gainDry.gain.value = event.target.value
         console.log(event.target.value)

       changeLevelWet: ->
         @gainWet.gain.value = event.target.value
         console.log(event.target.value)

       changeDistance: ->
         @filter.setFrequency(event.target.value)


    audioContext = new webkitAudioContext
    filter = new Filter(audioContext)
    noise = new WhiteNoise(audioContext)
    envelope = new Envelope(audioContext)
    gainDry = audioContext.createGainNode()
    gainWet = audioContext.createGainNode()
    merger1 = audioContext.createChannelMerger()
    impulseBuffer = null
    convolver = audioContext.createConvolver()


    request = new XMLHttpRequest()
    request.open('GET', '/audio/bright_plate.wav', true)
    request.responseType = 'arraybuffer'

    request.onload = =>
      onsuccess = (buffer) ->
        impulseBuffer = buffer
        convolver.buffer = impulseBuffer

      onerror = -> alert "Could not load #{self.url}"

      audioContext.decodeAudioData request.response, onsuccess, onerror
    request.send()

    noise.node.connect(envelope.node)
    envelope.node.connect(filter.node)
    filter.node.connect(gainDry)
    filter.node.connect(convolver)
    convolver.connect(gainWet)
    gainDry.connect(merger1)
    gainWet.connect(merger1)

    merger1.connect(audioContext.destination)

    new ControlView(filter,envelope,gainDry,gainWet,audioContext)

    volume_knob = new KnobView(el: '#volume')
    rate_of_fire_knob = new KnobView(el: '#rate-of-fire')
    distance_knob = new KnobView(el: '#distance')
    multi_fire_switch = new SwitchView(el: '#multi-fire')
    trigger = $('#trigger')

    volume_knob.on('valueChanged',
      (v) -> console.log(v) )

    distance_knob.on('valueChanged',
      (v) -> console.log(v) )

    rate_of_fire_knob.on('valueChanged',
      (v) -> console.log(v) )

    trigger.click(-> envelope.impulse() )

)