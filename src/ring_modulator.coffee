# # Ring Modulator
#
# Ring Modulation is one of the most recognisable effects used by the
# Radiophonic Workshop. It was the effect used to create the voices of
# both the Cybermen and The Daleks for Dr Who.
#
# To create the voice of the Daleks they used a 30Hz sine wave as the
# modulating signal - this was recorded onto a tape loop and connected
# to one input. A microphone was connected to the second (carrier)
# input. The actor could then use the effect live on the set of Dr
# Who.
#
# It was quite common for the tape to be run at the wrong speed by
# mistake which is why on some episodes the Daleks sound slightly
# different. [Reference to SOS]
#
# This application is a digital simulation of a Diode based Ring
# Modulator of the type used by the Radiophonic Workshop. [Reference
# to J Parker]

# # Preamble
#
# We use jQuery, backbone.js and some custom UI elements (namely a
# [knob](views/knob.html) and a [switch](views/switch.html)) in this
# application. We make these libraries available to our application
# using [require.js](http://requirejs.org/)
require(["jquery", "backbone", "knob", "speechbubble"], ($, Backbone, KnobView, SpeechBubbleView) ->
  $(document).ready ->
    # We need to alert the user if the Web Audio API is not available.
    # Testing for the existence of `webkitAudioContext` is currently a
    # good way to achieve that.
    if typeof(webkitAudioContext) == 'undefined' && typeof(AudioContext) == 'undefined'
      alert 'Your browser does not support the Web Audio API. Try Google Chrome or a Webkit nightly build'

    # # AudioNodeBase
    #
    # A simple base class to provide the correct destination type to
    # an audio node and call the connect method.
    class AudioNodeBase
      connect: (destination) ->
        if (typeof destination.node=='object')
          d = destination.node
        else
          d = destination

        @node.connect(d)

    # # SamplePlayer
    #
    # This class uses native audio buffer nodes to load and playback
    # samples. It requires an audio context.
    class SamplePlayer extends Backbone.View
      constructor: (@context) ->

      play: () ->
        this.stop()
        # Create a new source
        @source = @context.createBufferSource()
        # Assign the previously loaded buffer to the source
        @source.buffer = @buffer
        # Enable looping
        @source.loop = true
        # Connect the source
        @source.connect(@destination)
        # Play now
        @source.noteOn 0

      stop: ->
        if @source
          # Stop the source from playing
          @source.noteOff 0
          @source.disconnect

      # Connect method - we cannot just inherit audio node base as we
      # do not want to perform the connection when the graph is built
      connect: (destination) ->
        if (typeof destination.node=='object')
          @destination = destination.node
        else
          @destination = destination

      loadBuffer: (url) ->
        self = this
        request = new XMLHttpRequest()
        request.open('GET', url, true)
        request.responseType = 'arraybuffer'

        request.onload = =>
          onsuccess = (buffer) ->
            self.buffer = buffer
            self.trigger('bufferLoaded')

          onerror = -> alert "Could not load #{self.url}"

          @context.decodeAudioData request.response, onsuccess, onerror

        request.send()

    # # Oscillator
    #
    # This is our principle oscillator node. It implements a sine-wave
    # oscillator where the primary frequency is a modifiable
    # parameter. At the time of writing the "native" [Oscillator
    # interface](https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#Oscillator)
    # is not available in any stable version of Webkit, so we use a
    # [JavaScript
    # node](https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#JavaScriptAudioNode)
    # instead.
    class Oscillator
      constructor: (@context,frequency) ->
        # The node has 0 input channels and one output channel.  The `process` callback is called every 1024
        # samples.
        @node = @context.createJavaScriptNode(1024, 1, 1)
        @node.onaudioprocess = (e) => this.process(e)

        @phase = 0
        @frequency = frequency
        @sample_rate = @context.sampleRate
        @amplitude = 1
        @counter = 0

      process: (e) ->
        # This Oscillator generates a mono output so we only assign
        # samples to a single output channel
        data = e.outputBuffer.getChannelData(0)

        # In for each block of 1024 samples we produce a sine wave. We
        # accumulate the changes in phase in an instance variable
        # `phase` so that it is carried over each time the callback is
        # called. This prevents audible glitching.
        for i in [0..data.length-1]
          sample = @amplitude * Math.sin(@phase)
          data[i] = sample
          @phase = @phase + ((2 * Math.PI * @frequency)  / @sample_rate)

    class InversionNode extends AudioNodeBase
      constructor: (@context) ->
        @node = @context.createJavaScriptNode(1024, 1, 1)
        @node.onaudioprocess = (e) => this.process(e)

      process: (e) ->
        input0_data = e.inputBuffer.getChannelData(0)
        output0_data = e.outputBuffer.getChannelData(0)

        for i in [0..output0_data.length-1]
          output0_data[i] = -1 * input0_data[i]

    # # Diode
    #
    # This class simulates the diode in Parker's paper using the Web
    # Audio API's WaveShaper node.
    class DiodeNode extends AudioNodeBase
      constructor: (@context) ->
        @node = @context.createWaveShaper()
        @vb = 0.2
        @vl = 0.4
        @h = 1
        this.setCurve()

      setDistortion: (distortion) ->
        #TODO: Set the distortion by shaping the whole curve, not just
        #the vb threshold.
        @vb = distortion
        this.setCurve()

      setCurve: ->
        samples = 1024;
        wsCurve = new Float32Array(samples);

        for i in [0...wsCurve.length]
          # convert the index to a voltage of range -1 to 1
          v = (i - samples/2) / (samples/2)
          v = Math.abs(v)

          if (v <= @vb)
            value = 0
          else if ((@vb < v) && (v <= @vl))
            value = @h * ((Math.pow(v-@vb,2)) / (2*@vl - 2*@vb))
          else
            value = @h*v - @h*@vl + (@h*((Math.pow(@vl-@vb,2))/(2*@vl - 2*@vb)))

          wsCurve[i] = value

        @node.curve = wsCurve

    # # PassThroughNode
    #
    # At the time of writing any javascript node will delay its
    # incoming audio signal by value of the blocksize. So in this
    # instance each of our javascript nodes delays the audio signal by
    # 1024 samples. This passthrough node has 1 input and 1 output and
    # simple copies the samples from the input to the output. It can
    # be used to compensate for delays introduced by javascript nodes
    # elsewhere in the graph.
    class PassThroughNode extends AudioNodeBase
      constructor: (@context) ->
        @node = @context.createJavaScriptNode(1024, 1, 1)
        @node.onaudioprocess = (e) => this.process(e)

      process: (e) ->
        input0_data = e.inputBuffer.getChannelData(0)
        output0_data = e.outputBuffer.getChannelData(0)

        for i in [0..output0_data.length-1]
          output0_data[i] = input0_data[i]

    # # AdditionNode
    #
    # Although some native nodes sum on input we have decided to
    # explicitly define our addition function for clarity. This node
    # has 2 inputs (stereo) and 1 output (mono). It sums the values of
    # the left and right input and sends them to the single output.
    class Addition extends AudioNodeBase
      constructor: (context) ->
        @context = context
        @node = @context.createJavaScriptNode(1024, 2, 1)
        @node.onaudioprocess = (e) => this.process(e)

      process: (e) ->
        datain0 = e.inputBuffer.getChannelData(0)
        datain1 = e.inputBuffer.getChannelData(1)
        dataout0 = e.outputBuffer.getChannelData(0)

        for i in [0..dataout0.length-1]
          dataout0[i] = datain0[i] +  datain1[i]

    # # Connect the graph
    audioContext = new webkitAudioContext

    # vIn Signal path objects
    vIn = new Oscillator(audioContext,30)
    vInGain = audioContext.createGainNode()
    vInGain.gain.value = 0.5
    vInSplitter1 = audioContext.createChannelSplitter()
    vInDelay1 = new PassThroughNode(audioContext)
    vInInverter1 = new InversionNode(audioContext)
    vInSplitter2 = audioContext.createChannelSplitter()
    vInMerger1 = audioContext.createChannelMerger()
    vInAddition1 = new Addition(audioContext)
    vInDelay2 = new PassThroughNode(audioContext)
    vInInverter2 = new InversionNode(audioContext)
    vInDiode1 = new DiodeNode(audioContext)
    vInDiode2 = new DiodeNode(audioContext)
    vInSplitter3 = audioContext.createChannelSplitter()
    vInSplitter4 = audioContext.createChannelSplitter()
    vInMerger2 = audioContext.createChannelMerger()
    vInAddition2 = new Addition(audioContext)
    vInInverter3 = new InversionNode(audioContext)
    vInSplitter5 = audioContext.createChannelSplitter()
    vInCrossSplitter = audioContext.createChannelSplitter()

    # vc Signal path objects
    player = new SamplePlayer(audioContext)

    vcSplitter1 = audioContext.createChannelSplitter()
    vcMerger1 = audioContext.createChannelMerger()
    vcAddition1 = new Addition(audioContext)
    vcDelay1 = new PassThroughNode(audioContext)
    vcInverter1 = new InversionNode(audioContext)
    vcDiode1 = new DiodeNode(audioContext)
    vcDiode2 = new DiodeNode(audioContext)
    vcSplitter2 = audioContext.createChannelSplitter()
    vcSplitter3 = audioContext.createChannelSplitter()
    vcMerger2 = audioContext.createChannelMerger()
    vcAddition2 = new Addition(audioContext)
    vcDelay2 = new PassThroughNode(audioContext)
    vcSplitter4 = audioContext.createChannelSplitter()

    # output Signal path objects
    outMerger1 = audioContext.createChannelMerger()
    outAddition = new Addition(audioContext)
    outSplitter = audioContext.createChannelSplitter()
    outMerger2 = audioContext.createChannelMerger()

    #vc Input Graph
    player.connect(vcSplitter1)
    vcSplitter1.connect(vcMerger1)
    vcMerger1.connect(vcAddition1.node)

    #vIn Input Graph
    vIn.node.connect(vInGain)
    vInGain.connect(vInSplitter1)
    vInSplitter1.connect(vInInverter1.node)
    vInInverter1.connect(vInSplitter2)
    vInSplitter2.connect(vInMerger1,0,0)
    vInMerger1.connect(vInAddition1.node)

    #Crossover input graph
    vcSplitter1.connect(vInMerger1,0,1)
    vInGain.connect(vInDelay1.node)
    vInDelay1.connect(vInCrossSplitter)
    vInCrossSplitter.connect(vcMerger1,0,1)

    # vc Ring Graph
    # Top
    vcAddition1.connect(vcDelay1.node)
    vcDelay1.connect(vcDiode1.node)
    vcDiode1.connect(vcSplitter2)
    vcSplitter2.connect(vcMerger2,0,0)
    # Bottom
    vcAddition1.connect(vcInverter1.node)
    vcInverter1.connect(vcDiode2.node)
    vcDiode2.connect(vcSplitter3)
    vcSplitter3.connect(vcMerger2,0,1)
    # output
    vcMerger2.connect(vcAddition2.node)
    vcAddition2.connect(vcDelay2.node)
    vcDelay2.connect(vcSplitter4)
    vcSplitter4.connect(outMerger1,0,0)

    # vIn Ring graph
    # Top
    vInAddition1.connect(vInDelay2.node)
    vInDelay2.connect(vInDiode1.node)
    vInDiode1.connect(vInSplitter3)
    vInSplitter3.connect(vInMerger2,0,0)
    # Bottom
    vInAddition1.connect(vInInverter2.node)
    vInInverter2.connect(vInDiode2.node)
    vInDiode2.connect(vInSplitter4)
    vInSplitter4.connect(vInMerger2,0,1)
    # output
    vInMerger2.connect(vInAddition2.node)
    vInAddition2.connect(vInInverter3.node)
    vInInverter3.connect(vInSplitter5)
    vInSplitter5.connect(outMerger1,0,1)

    # output graph
    outMerger1.connect(outAddition.node)
    outAddition.connect(outSplitter)
    outSplitter.connect(outMerger2,0,0)
    outSplitter.connect(outMerger2,0,1)

    outMerger2.connect(audioContext.destination)

    # # User Interface
    bubble1 = new SpeechBubbleView(el: $("#voice1"))
    bubble2 = new SpeechBubbleView(el: $("#voice2"))
    bubble3 = new SpeechBubbleView(el: $("#voice3"))
    bubble4 = new SpeechBubbleView(el: $("#voice4"))

    speedKnob = new KnobView(el: $("#tape-speed"), initial_value: 0.01)
    distortionKnob = new KnobView(el: $("#mod-distortion"), initial_value: 0.4)

    speedKnob.on('valueChanged', (v) =>
      # Scale the [0,1] input from the KnobView into an appropriate range.
      speed = v * (10 - 2000) + 10
      vIn.frequency = speed
    )

    distortionKnob.on('valueChanged', (v) =>
      _.each([vInDiode1, vInDiode2, vcDiode1, vcDiode2], (diode) -> diode.setDistortion(v))
    )

    bubble1.on('on', ->
      _.each([bubble2, bubble3, bubble4], (o) -> o.turnOff() )
      player.loadBuffer("/audio/ringmod_exterminate.wav")
      player.on('bufferLoaded', -> player.play())
    )

    bubble1.on('off', ->
      player.stop()
    )

    bubble2.on('on', ->
      _.each([bubble1, bubble3, bubble4], (o) -> o.turnOff() )
      player.loadBuffer("/audio/ringmod_good-dalek.wav")
      player.on('bufferLoaded', -> player.play())
    )

    bubble2.on('off', ->
      player.stop()
    )

    bubble3.on('on', ->
      _.each([bubble1, bubble2, bubble4], (o) -> o.turnOff() )
      player.loadBuffer("/audio/ringmod_upgrading.wav")
      player.on('bufferLoaded', -> player.play())
    )

    bubble3.on('off', ->
      player.stop()
    )

    bubble4.on('on', ->
      _.each([bubble1, bubble2, bubble3], (o) -> o.turnOff() )
      player.loadBuffer("/audio/ringmod_delete.wav")
      player.on('bufferLoaded', -> player.play())
    )

    bubble4.on('off', ->
      player.stop()
    )
)
