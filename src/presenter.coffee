define ['jquery', 'scroll-events', 'jquery.viewport', 'jquery.scrollTo', 'jquery.easing', 'jquery.stellar'], ($) ->

  # if typeof(webkitAudioContext) == 'undefined' && typeof(AudioContext) == 'undefined'
  #   alert 'Your browser does not support the Web Audio API'

	toggleScrollDownHint = ->
		visibleEls = $('.area:in-viewport')
		if $(visibleEls).is $('.area')[0]
			$('nav .hint').addClass('is-visible')
		else
			$('nav .hint').removeClass('is-visible')

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

		$('.hint').on('click', (evt) ->
			evt.preventDefault()
			$.scrollTo $('.area')[1], duration:500
		)

		# Use stellar when the window object scrolls
		$(window).stellar()

	$(document).ready(init)
