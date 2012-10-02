#
# TODO:	To use the grubmle and waypoints code below, add the following 2 dependencies
#		the array below: 'lib/grumble/js/jquery.grumble.js', 'waypoints'
define ['jquery', 'scroll-events', 'jquery.viewport', 'jquery.scrollTo', 'jquery.easing', 'jquery.stellar'], ($) ->

  # if typeof(webkitAudioContext) == 'undefined' && typeof(AudioContext) == 'undefined'
  #   alert 'Your browser does not support the Web Audio API'

  	# If the first .area element is visible in the viewport, the 'Scroll down' 
  	# .hint is shown otherwise it is hidden
	toggleScrollDownHint = ->
		visibleEls = $('.area:in-viewport')
		if $(visibleEls).is $('.area')[0]
			$('nav .hint').addClass('is-visible')
		else
			$('nav .hint').removeClass('is-visible')

	# When there are 2 .area elements visible within the browser viewport 
	# the element with the most visible height is scrolled into view.
	#
	# BUG: 	If there is only 1 element visible, no scrolling takes place
	#       due to a bug where the scrollstop event fires too many times
	#		causing a visual 'jumping' effect when scrolling.
	# TODO: Fix so that this scrolls when only 1 element is visible
	scrollMostVisibleElementIntoView = ->
		visibleEls = $('.area:in-viewport')
		console.log('visible', visibleEls)

		return if visibleEls.length < 2

		windowScrollTop = $(window).scrollTop()
		console.log 'window.scrollTop', windowScrollTop

		viewportHeight = $(window).height()
		console.log 'viewportHeight', viewportHeight

		mostVisible = null

		visibleEls.each () ->
			console.log('------->', this)

			offsetTop = $(this).offset().top
			viewportOffset = offsetTop - windowScrollTop

			console.log 'viewportOffset', viewportOffset, (viewportOffset > 0)

			height = $(this).height()

			if viewportOffset > 0
				visibleHeight = (windowScrollTop + viewportHeight) - offsetTop
			else
				visibleHeight = (offsetTop + height) - windowScrollTop

			console.log 'height %o, visibleHeight %o', height, visibleHeight

			unless mostVisible?
				mostVisible = el:this, height:visibleHeight
				console.log('setting mostVisible height', mostVisible?.height)

			if mostVisible? && (mostVisible.height < visibleHeight)
				mostVisible = el:this, height:visibleHeight
				console.log('setting mostVisible height', mostVisible?.height)

		console.log('mostVisible', mostVisible, $('.area')[0])

		$.scrollTo(mostVisible.el, axis:'y', duration:500, easing:'easeOutQuart')

	init = ->
		console.log('init')
		# Scroll an area into view when scrolling stops
		$(window).bind('scrollstop', scrollMostVisibleElementIntoView)

		# Scroll area into view when browser window is resized
		$(window).bind('resize', scrollMostVisibleElementIntoView)

		# When a scrolling, check if we should toggle visibility of "scroll down" message
		$(window).bind('scroll', toggleScrollDownHint)

		# When the 'Scroll down' arrow is pressed on the first .area element
		# the page is scrolled to whatever the second .area element is
		$('.hint').on('click', (evt) ->
			evt.preventDefault()
			$.scrollTo $('.area')[1], duration:500
		)

		# When an internal page link is clicked, scroll to the target
		# instead of just jumping there
		$(document).on('click', "[href^='#']", (evt) ->
			href = $(this).attr('href')
			el   = $(href)
			if el.length > 0
				$.scrollTo el, duration:500
				evt.preventDefault()
		)

		###
		# This uses the 'Waypoint' plugin to activate a 'grumble' tooltip box when 
		# the machine is scrolled into view
		# TODO: Hook this up listen for machine events so that we can hide the callout 
		# 		when the machine's activate. Does grumble provide an API for this?
		$('#machine-wrapper').waypoint ->
			machineOnOffSwitch = $('#switch')
			opts = text: 'Switch on the machine', angle: 240, distance: 20, showAfter: 500

			$(machineOnOffSwitch).grumble(opts)
		###

		# Use stellar when the window object scrolls
		$(window).stellar()

	$(document).ready(init) unless /no-scroll/.test window.location.hash
