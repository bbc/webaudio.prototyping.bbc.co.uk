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


    # # Connect the graph
    audioContext = new webkitAudioContext

    # vIn Signal path objects
    vIn = audioContext.createOscillator()
    vIn.frequency.value = 30
    vIn.noteOn(0) 
    vInGain = audioContext.createGainNode()
    vInGain.gain.value = 0.5
    
    vInInverter1 = audioContext.createGainNode()
    vInInverter1.gain.value = -1
    
    vInInverter2 = audioContext.createGainNode()
    vInInverter2.gain.value = -1
    
    vInDiode1 = new DiodeNode(audioContext)
    vInDiode2 = new DiodeNode(audioContext)
    
    vInInverter3 = audioContext.createGainNode()
    vInInverter3.gain.value = -1


    # vc Signal path objects
    player = new SamplePlayer(audioContext)

    vcInverter1 = audioContext.createGainNode()
    vcInverter1.gain.value = -1
    vcDiode3 = new DiodeNode(audioContext)
    vcDiode4 = new DiodeNode(audioContext)

    # output Signal path objects

    #vc Input Graph
    player.connect(vcInverter1)
    player.connect(vcDiode4)
    console.debug()
    vcInverter1.connect(vcDiode3.node)

    #vIn Input Graph
    vIn.connect(vInGain)
    vInGain.connect(vInInverter1)
    vInGain.connect(vcInverter1)
    vInGain.connect(vcDiode4.node)
    
    vInInverter1.connect(vInInverter2)
    vInInverter1.connect(vInDiode2.node)
    vInInverter2.connect(vInDiode1.node)
    vInDiode1.connect(vInInverter3)
    vInDiode2.connect(vInInverter3)
    vInInverter3.connect(audioContext.destination)
    vcDiode3.connect(audioContext.destination)
    vcDiode4.connect(audioContext.destination)
    # # User Interface
    bubble1 = new SpeechBubbleView(el: $("#voice1"))
    bubble2 = new SpeechBubbleView(el: $("#voice2"))
    bubble3 = new SpeechBubbleView(el: $("#voice3"))
    bubble4 = new SpeechBubbleView(el: $("#voice4"))

    speedKnob = new KnobView(
     el: "#tape-speed"
     initial_value: 30
     valueMin: 0 
     valueMax: 2000
    )

    distortionKnob = new KnobView(el: $("#mod-distortion"), initial_value: 0.4)

    speedKnob.on('valueChanged', (v) =>
      vIn.frequency.value = v
    )

    distortionKnob.on('valueChanged', (v) =>
      _.each([vInDiode1, vInDiode2, vcDiode3, vcDiode4], (diode) -> diode.setDistortion(v))
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
