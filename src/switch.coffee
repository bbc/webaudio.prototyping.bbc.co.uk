# # SwitchView
#
# This class implements a Backbone View that can be bound to a DOM
# element to turn it into a toggle switch.
define(['backbone'], ->
  class SwitchView extends Backbone.View
    # The switch defaults to off (0).
    initialize: () ->
      @count = 0
      @states = @options.states || ['off', 'on']

    # When the switch is `click`ed ...
    events:
      "click": "incrementState"

    # ... increment the state counter and trigger the new state
    incrementState: ->
      @count = @count + 1
      state = @states[@count % @states.length]
      this.trigger(state)
      $(this.el).removeClass(@states.join(' ')).addClass(state)
)