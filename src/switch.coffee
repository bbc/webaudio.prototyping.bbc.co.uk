# # SwitchView
#
# This class implements a Backbone View that can be bound to a DOM
# element to turn it into a toggle switch.
define(['backbone'], ->
  class SwitchView extends Backbone.View
    # The switch defaults to off (0).
    initialize: () ->
        @state = 0

    # When the switch is `click`ed ...
    events:
      "click": "toggle"

    # ... if the switch is on (1) turn it off; if it's off (0) turn it
    # on.
    toggle: ->
      if (@state == 0)
        @state = 1
        this.turnOn()
      else
        this.turnOff()
        @state = 0

    # Fire a custom `on` or `off` event and set the corresponding
    # class on the view's DOM element
    turnOn: ->
      this.trigger('on')
      $(this.el).removeClass('off').addClass('on')

    turnOff: ->
      this.trigger('off')
      $(this.el).removeClass('on').addClass('off')
)