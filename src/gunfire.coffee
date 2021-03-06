#
# ![Block diagram of the Electronic Gunfire Effects Generator](/img/gunfire_block_diagram.png "Block diagram")
#
# # Preamble
#
# We use jQuery, backbone.js and some custom UI elements (namely a
# [knob](/docs/knob.html) and a [switch](/docs/switch.html)) in this
# application. We make these libraries available to our application
# using [require.js](http://requirejs.org/).
require(["jquery", "backbone", "knob", "switch"], ($, Backbone, Knob, Switch) ->
  $(document).ready ->

    # # Player
    #
    # This class wraps an [AudioBufferSourceNode](https://webaudio.github.io/web-audio-api/#idl-def-AudioBufferSourceNode)
    # and loads the audio from a given URL.
    class Player
      constructor: (@url) ->
        this.loadBuffer()
        # This BufferSource plays a white noise signal read in from a WAV file.
        @source = audioContext.createBufferSource()

      play: ->
        if @buffer
          # Set the buffer of a new AudioBufferSourceNode equal to the
          # samples loaded by `loadBuffer`.

          @source.buffer = @buffer
          @source.loop = true
          @source.start 0

      # Load the samples from the provided `url`, decode and store in
      # an instance variable.
      loadBuffer: ->
        self = this

        request = new XMLHttpRequest()
        request.open('GET', @url, true)
        request.responseType = 'arraybuffer'

        # Load the decoded sample into the buffer if the request is successful.
        request.onload = =>
          onsuccess = (buffer) ->
            self.buffer = buffer
            self.play()

          onerror = -> alert "Could not decode #{self.url}"

          audioContext.decodeAudioData request.response, onsuccess, onerror

        request.send()

      # # WhiteNoise
      #
      # Instead of using an AudioBufferSourceNode, the same effect could be
      # achieved using a [ScriptProcessorNode](https://webaudio.github.io/web-audio-api/#idl-def-ScriptProcessorNode).
      class WhiteNoise
        constructor: (context) ->
          self = this
          @context = context
          @node = @context.createScriptProcessor(1024, 1, 2)
          @node.onaudioprocess = (e) -> self.process(e)

        process: (e) ->
          data0 = e.outputBuffer.getChannelData(0)
          data1 = e.outputBuffer.getChannelData(1)
          # Generate random numbers in the range of -1 to 1.
          for i in [0...data0.length]
            data0[i] = Math.random() * 2 - 1
            data1[i] = data0[i]

        connect: (destination) ->
          @node.connect(destination)

    # # Envelope
    #
    # This class uses a gain node to generate a volume ramp at specific times
    # to simulate the attack and release time of the gunshot.
    class Envelope
      constructor: () ->
        @node = audioContext.createGain()
        @node.gain.value = 0

      addEventToQueue: () ->
        # Set gain to 0 "now".
        @node.gain.linearRampToValueAtTime(0, audioContext.currentTime);
        # Attack: ramp to 1 in 0.0001ms.
        @node.gain.linearRampToValueAtTime(1, audioContext.currentTime + 0.001);
        # Decay: ramp to 0.3 over 100ms.
        @node.gain.linearRampToValueAtTime(0.3, audioContext.currentTime + 0.101);
        # Release: ramp down to 0 over 500ms.
        @node.gain.linearRampToValueAtTime(0, audioContext.currentTime + 0.500);

    # Now we create and connect the noise to the envelope generators
    # so that they can be triggered by the timing node.
    # We also create 4 voices to allow shots to overlap.
    audioContext = new AudioContext
    # Create the noise source.
    noise = new Player("/audio/white_noise.wav")

    # We create 4 instances of the envelope class to provide 4 separate voices.
    # This is necessary as if the rate of fire is very fast the envelope will not
    # have time to reach zero before being triggered again.
    voice1 = new Envelope()
    voice2 = new Envelope()
    voice3 = new Envelope()
    voice4 = new Envelope()

    # Connect the noise source to the 4 voices.
    noise.source.connect(voice1.node)
    noise.source.connect(voice2.node)
    noise.source.connect(voice3.node)
    noise.source.connect(voice4.node)

    # Connect the voice outputs to a low-pass filter to allow a simulation of
    # distance.
    filter = audioContext.createBiquadFilter()
    filter.type = "lowpass"
    filter.Q.value = 1
    filter.frequency.value = 800

    # Connect the voices to the filter.
    voice1.node.connect(filter)
    voice2.node.connect(filter)
    voice3.node.connect(filter)
    voice4.node.connect(filter)

    # Connect the filter to a master gain node.
    gainMaster = audioContext.createGain()
    gainMaster.gain.value = 5
    filter.connect(gainMaster)

    # Connect the gain node to the output destination.
    gainMaster.connect(audioContext.destination)

    voiceSelect = 0
    fireRate = 1100 # 50% of 200ms to 2000ms range
    intervalTimer = null

    # A function to select the next voice and queue the event.
    fire = () ->
      voiceSelect++
      if voiceSelect > 4 then voiceSelect = 1
      if voiceSelect == 1 then voice1.addEventToQueue()
      if voiceSelect == 2 then voice2.addEventToQueue()
      if voiceSelect == 3 then voice3.addEventToQueue()
      if voiceSelect == 4 then voice4.addEventToQueue()

    # A function to repeatedly fire the gunshot when the rapid fire switch is
    # on.
    schedule = () ->
      fire()
      if intervalTimer != null
        intervalTimer = setTimeout(schedule, fireRate)

    # Set up the controls.
    volumeKnob = new Knob(el: '#volume')
    rateOfFireKnob = new Knob(el: '#rate-of-fire')
    distanceKnob = new Knob(el: '#distance')
    multiFireSwitch = new Switch(el: '#multi-fire')
    trigger = $('#trigger')

    # Set the rapid fire rate.
    multiFireSwitch.on('on', =>
      fire()
      intervalTimer = setTimeout(schedule, fireRate)
    )

    # Clear the rapid fire function.
    multiFireSwitch.on('off', =>
      clearInterval(intervalTimer)
      intervalTimer = null
    )

    # Set the master gain value.
    volumeKnob.on('valueChanged', (v) =>
      gainMaster.gain.value = v * 20
    )

    # Set the filter frequency.
    distanceKnob.on('valueChanged', (v) =>
      filter.frequency.value = 100 + (1.0 - v) * 800
    )

    # Change the rate of fire. The knob provides a value from 0 to 1, from
    # which we compute the rate of fire, in the range 2000ms to 200ms.
    rateOfFireKnob.on('valueChanged', (v) =>
      fireRate = 200 + (1.0 - v) * 1800
    )

    # Trigger a single shot.
    trigger.click(fire)
)
