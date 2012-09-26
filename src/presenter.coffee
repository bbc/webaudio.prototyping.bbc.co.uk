define ['jquery', 'scroll-events', 'jquery.viewport', 'jquery.scrollTo', 'jquery.easing'], ($) ->

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

		console.log('mostVisible', mostVisible)
		$.scrollTo(mostVisible.el, axis:'y', duration:500, easing:'easeOutQuart')

	# Scroll an area into view when scrolling stops
	$(window).bind('scrollstop', scrollMostVisibleElementIntoView)	

	# Scroll area into view when browser window is resized
	$(window).bind('resize', scrollMostVisibleElementIntoView)
