#
# ![Block diagram of the Electronic Gunfire Effects Generator](/img/gunfire_block_diagram.png "Block diagram")
#
# # Preamble
#
# We use jQuery, backbone.js and some custom UI elements (namely a
# [knob](knob.html) and a [switch](switch.html)) in this
# application. We make these libraries available to our application
# using [require.js](http://requirejs.org/)
require(["jquery", "backbone", "knob", "switch"], ($, Backbone, Knob, Switch) ->
  $(document).ready ->

    class audioRateTimer
      constructor: (@context) ->
        self = this
        @node = @context.createJavaScriptNode(1024, 1, 2)
        @node.onaudioprocess = (e) => @process(e)

        @count = 0
        @voice = 0
        @frequency = 0
        @sample_rate = context.sampleRate

      process: (e) ->
        data_l = e.outputBuffer.getChannelData(0)
        data_r = e.outputBuffer.getChannelData(1)

        for i in [0..data_l.length-1]
          @count++
          if @count >= @sample_rate / @frequency
            @voice++
            @count = 0
            if @voice == 1
              envelope1.impulse()
            else if @voice == 2
              envelope2.impulse()
            else if @voice == 3
              envelope3.impulse()
            else if @voice == 4
              envelope4.impulse()
              @voice = 0

    class WhiteNoise
      constructor: (context) ->
        self = this
        @context = context
        @node = @context.createJavaScriptNode(1024, 1,2)
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
        @node.Q.value = 1
        @node.frequency.value = 800

      setFrequency: (frequency)->
        @node.frequency.value = frequency

    class Envelope
      constructor: (context) ->
        self = this
        @context = context
        @decayTime = 0.150
        @node = @context.createGainNode()
        @node.gain.value = 0

      impulse: ->
        @node.gain.linearRampToValueAtTime(0, @context.currentTime);
        @node.gain.linearRampToValueAtTime(1, @context.currentTime + 0.001);
        @node.gain.linearRampToValueAtTime(0.3, @context.currentTime + 0.101);
        @node.gain.linearRampToValueAtTime(0, @context.currentTime + @decayTime);

      setDecay: (decay) ->
        @decayTime = ((1 - decay) * 2) + 0.150

    audioContext = new webkitAudioContext
    time = new audioRateTimer(audioContext)
    filter = new Filter(audioContext)
    noise = new WhiteNoise(audioContext)
    envelope1 = new Envelope(audioContext)
    envelope2 = new Envelope(audioContext)
    envelope3 = new Envelope(audioContext)
    envelope4 = new Envelope(audioContext)
    envelope5 = new Envelope(audioContext)
    gainRapid = audioContext.createGainNode()
    gainRapid.gain.value = 0
    gainDry = audioContext.createGainNode()
    gainWet = audioContext.createGainNode()
    gainMaster = audioContext.createGainNode()
    merger1 = audioContext.createChannelMerger()
    impulseBuffer = null
    convolver = audioContext.createConvolver()
    


    request = new XMLHttpRequest()
    request.open('GET', '/audio/bright_space.wav', true)
    request.responseType = 'arraybuffer'

    request.onload = =>
      onsuccess = (buffer) ->
        impulseBuffer = buffer
        convolver.buffer = impulseBuffer

      onerror = -> alert "Could not load #{self.url}"

      audioContext.decodeAudioData request.response, onsuccess, onerror
    request.send()

    noise.node.connect(envelope1.node)
    noise.node.connect(envelope2.node)
    noise.node.connect(envelope3.node)
    noise.node.connect(envelope4.node)
    noise.node.connect(envelope5.node)
    envelope1.node.connect(gainRapid)
    envelope2.node.connect(gainRapid)
    envelope3.node.connect(gainRapid)
    envelope4.node.connect(gainRapid)
    envelope5.node.connect(filter.node)
    gainRapid.connect(filter.node)
    filter.node.connect(gainDry)
    filter.node.connect(convolver)
    convolver.connect(gainWet)
    gainDry.connect(merger1)
    gainWet.connect(merger1)
    gainWet.gain.value = 0.2
    gainMaster.gain.value = 10
    merger1.connect(gainMaster)
    time.node.connect(audioContext.destination)
    gainMaster.connect(audioContext.destination)

    volume_knob = new Knob(el: '#volume')
    rate_of_fire_knob = new Knob(el: '#rate-of-fire')
    distance_knob = new Knob(el: '#distance')
    multi_fire_switch = new Switch(el: '#multi-fire')
    trigger = $('#trigger')

    multi_fire_switch.on('on', =>
      gainRapid.gain.value = 1
      time.frequency = 2
    )

    multi_fire_switch.on('off', =>
      time.frequency = 0
      gainRapid.gain.value = 0
    )

    volume_knob.on('valueChanged', (v) =>
      gainMaster.gain.value = v * 20
    )

    distance_knob.on('valueChanged', (v) =>
      filter.setFrequency((v * 800) + 100)
    )

    rate_of_fire_knob.on('valueChanged', (v) =>
      time.frequency = (v + 1) * 5
      envelope1.setDecay(v)
      envelope2.setDecay(v)
      envelope3.setDecay(v)
      envelope4.setDecay(v)
    )

    trigger.click(-> envelope5.impulse() )

)
