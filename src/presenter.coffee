#
define(['require', 'underscore', 'jquery', 'jquery-plugins'], 
	
(require, _, $) ->

	logger = 
		log: ->
			console.log.apply(console, arguments) if config.debug

	# Config settings
	config = 
		shouldToggleScrollDownHint: false
		scrollElementIntoViewOnScroll: false
		scrollElementIntoViewOnResize: true
		debug: false
		scrollDebounceTimeInMs: 300
		panelSelector: '.area'
		presentationModeQuerystring: 'presentation'
		useSharetools: true
		fullscreenButton: false
		forceWebAudioSupportMessage: false

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

	initScrollDownHint = ->
		if config.shouldToggleScrollDownHint
			$(window).bind('scroll', toggleScrollDownHint)

			# When the 'Scroll down' arrow is pressed on the first .area element
			# the page is scrolled to whatever the second .area element is
			$('.hint').on('click', (evt) ->
				evt.preventDefault()
				scrollTo $('.area')[1]
			)
		else
			$('nav .hint').removeClass('is-visible')

	# Wrap the jQuery.scrollTo plugin to pass in the same options
	# for a consistent scroll animation on the page
	scrollTo = (el) ->
  		$.scrollTo el, axis:'y', duration:1300, easing:'easeOutQuart'

	# When there are 2 .area elements visible within the browser viewport 
	# the element with the most visible height is scrolled into view.
	#
	# BUG: 	If there is only 1 element visible, no scrolling takes place
	#       due to a bug where the scrollstop event fires too many times
	#		causing a visual 'jumping' effect when scrolling.
	# TODO: Fix so that this scrolls when only 1 element is visible
	scrollMostVisibleElementIntoView = ->
		logger.log('scrollMostVisibleElementIntoView start')
		mostVisible = findMostVisibleEl()
		logger.log('mostVisible', mostVisible)
		if mostVisible?
			logger.log('scrollMostVisibleElementIntoView', mostVisible.el)
			scrollTo mostVisible.el 

	createScrollMostVisibleElementIntoViewWithDebouce = ->
		debouncedFunction = $.debounce(config.scrollDebounceTimeInMs, scrollMostVisibleElementIntoView)
		return debouncedFunction

	inverseScale = (progress) ->
		return 1-scale(progress)

	scale = (progress) ->
		if progress >= 0 && progress <= 0.4
			scaled = 1 - (progress * 2)
		else if progress >= 0.6 && progress <= 1
			scaled = (progress * 2) - 1
		else 
			scaled = 0

		return scaled

	updateNavButtons = ->
		windowScrollTop = $(window).scrollTop()

		el = $("#{config.panelSelector}:in-viewport")[0]
		if el?
			offset   = getOffsetsFor(el, windowScrollTop)
			progress = Math.abs( offset.viewportOffset / offset.height )
			opacity  = scale(progress)
		else
			offset = 0

		$('.prev.button').css 'opacity', opacity
		$('.next.button').css 'opacity', opacity

		currentPanelId = findCurrentPanelId()

		$('body').attr('data-section', currentPanelId)

		switch currentPanelId
			#when "intro" then navButtons(null, 'info')
			when "info"  then navButtons(null, 'demo')
			when "demo"  then navButtons('info', 'code') 
			when "code"	 then navButtons('demo', null) 

	navButtons = (prevLabel, nextLabel) ->
		if prevLabel
			$('.prev.button').show()
						   .attr('href', '#' + prevLabel)
						   .find('.label').text(prevLabel || '')
		else
			$('.prev.button').hide()

		if nextLabel
			$('.next.button').show()
							 .attr('href', '#' + nextLabel)
						     .find('.label').text(nextLabel || '')
		else
			$('.next.button').hide()

	findCurrentPanelId = ->
		current = findMostVisibleEl()
		return current?.el?.getAttribute('id')

	getOffsetsFor = (element, windowScrollTop) ->
		$el = $(element)

		# The height of this element
		height = $el.height()

		# The position of the top of this element from the canvas
		offsetTop = $el.offset().top

		# The position of the top of this element from the viewport
		viewportOffset = offsetTop - windowScrollTop

		return height:height, offsetTop:offsetTop, viewportOffset:viewportOffset

	# The browser *canvas* is the entire document
	# The browser *viewport* is the area that is currently visible to the user
	findMostVisibleEl = ->
		visibleEls = $("#{config.panelSelector}:in-viewport")
		logger.log('visible elements', visibleEls)

		# Short circuit if only 1 element is visible
		return el:visibleEls[0], height:null if visibleEls.length == 1

		# The distance from the top of the canvas to the top of the viewport
		windowScrollTop = $(window).scrollTop()
		logger.log 'window.scrollTop', windowScrollTop

		# The height of the viewport (i.e. what the user can see)
		viewportHeight = $(window).height()
		logger.log 'viewportHeight', viewportHeight

		mostVisible = null

		# For all visibile elements in the viewport
		visibleEls.each () ->
			logger.log('-----------------')
			logger.log(this)

			offsets = getOffsetsFor(this, windowScrollTop)

			logger.log 'viewportOffset', offsets.viewportOffset, (offsets.viewportOffset > 0)

			# The top of the element is visible in the viewport
			if offsets.viewportOffset > 0
				visibleHeight = (windowScrollTop + viewportHeight) - offsets.offsetTop
			# Else the top of the element is above the viewport
			else
				visibleHeight = (offsets.offsetTop + offsets.height) - windowScrollTop

			logger.log 'height %o, visibleHeight %o', offsets.height, visibleHeight

			# This is the first element we've found
			unless mostVisible?
				mostVisible = el:this, height:visibleHeight
				logger.log('setting mostVisible height', mostVisible?.height)

			# If a mostVisible element has already been found, work out if there's more
			# of the current element visible
			if mostVisible? && (mostVisible.height < visibleHeight)
				mostVisible = el:this, height:visibleHeight
				logger.log('setting mostVisible height', mostVisible?.height)

		logger.log('findMostVisibleEl - mostVisible', mostVisible, $('.area')[0])

		return mostVisible

	initScrollIntoView = ->
		# Scroll an area into view when scrolling stops
		if config.scrollElementIntoViewOnScroll
			logger.log('config.scrollElementIntoViewOnScroll')
			$(window).bind('scrollstop', createScrollMostVisibleElementIntoViewWithDebouce)

		if config.scrollElementIntoViewOnResize
			logger.log('config.scrollElementIntoViewOnResize')
			debouncedFunction = createScrollMostVisibleElementIntoViewWithDebouce()
			# Scroll area into view when browser window is resized
			$(window).bind('resize', debouncedFunction)

	initNavButtonUpdates = ->
		$(window).bind('scroll', updateNavButtons)
		$(window).bind('resize', updateNavButtons)
		updateNavButtons()

	getNavHeight = ->
		_.reduce(
			$('.project-header, .nav, .demo-header').toArray(),
			(prev, current) ->
				return prev + $(current).height()
			,0
		)

	scaleContent = ->
		#return 

		maxWidth  = 1424
		minWidth  = 1024
		minHeight = 464

		$contentAreas = $('.frame .content')
		viewportHeight = $(window).height()
		viewportWidth  = $(window).width()
		#fixedPanelHeight = getNavHeight()

		logger.log('viewport height %o width %o', viewportHeight, viewportWidth)

		topHeight    = 25 + 49
		bottomHeight = 49

		contentHeight = viewportHeight - topHeight - bottomHeight - 8 - 8
		contentWidth  = contentHeight * 2

		logger.log('contentHeight %o contentWidth %o', contentHeight, contentWidth)

		if contentWidth >= maxWidth
			contentWidth  = maxWidth 
			contentHeight = 712
		
		if contentWidth >= viewportWidth
			contentWidth  = viewportWidth - 8 - 8
			contentHeight = contentWidth / 2

		if contentWidth <= minWidth
			contentWidth = minWidth
			contentHeight = minWidth / 2
		else if contentHeight <= minHeight
			contentHeight = minHeight
			contentWidth  = minHeight * 2

		midHeight = (contentHeight / 2)

		marginTop = 0 - midHeight + ((topHeight - bottomHeight) / 2)
		marginLeft = Math.round(contentWidth / 2)
		margin = "#{marginTop}px 0 0 -#{marginLeft}px"
		
		$contentAreas.css(
			height: contentHeight
			width: contentWidth
			margin: margin
			'max-height': 'none'
			'max-width' : 'none'
		)

		$contentAreas.find('.image-block').css(
			'max-height': 'none'
			'max-width' : 'none'			
		)

		transformScale = contentWidth / maxWidth
		scaleMachine(transformScale)

		$('.project-header, .nav, .demo-header').find('.inner')
												.width(contentWidth)

		logger.log('Setting content areas to height %o, width %o (%o)', contentHeight, contentWidth, $contentAreas)

	initScaleContent = ->
		$(window).bind('resize', scaleContent)
		scaleContent()

	initPresentationMode = (modernizr, querystringParam) ->

		# We're in presentation mode
		$('body').addClass('presentation')

		# Create a scale control
		$el = $("""<div class="scale-control" 
						style="position:fixed; right:10px; top:10px; z-index:200; 
							 	width:170px; line-height:70px; height:70px; background-color:rgba(0,0,0,0.5); 
							 	border-radius:50px; text-align:center;">
						<input type="range" min=0 max=1 step=0.1 value=1 /> <span></span>
				</div>""")
		$input = $el.find('input')
		$label = $el.find('span')

		inputScale = $input.val()

		$('body').append($el)

		# Scale on input change
		handleChangeEvent = ->
			inputScale = $input.val()
			$label.text(inputScale)
			scaleMachine(inputScale)

		$input.on('change', handleChangeEvent)

		# Ensure all links also point to presentation mode
		$("a[href^='/']").each ->
			hrefWithQs = $(this).attr('href').replace(/#(.*)/, "?#{config.presentationModeQuerystring}#$1")
			$(this).attr('href', hrefWithQs)

	scaleMachine = (scaleValue) ->
			transformStyleName = Modernizr.prefixed('transform')
			$machine = $('#machine')
			#$machine[0].style[transformStyleName] = "scale3d(#{scaleValue},#{scaleValue},0)" if $machine.length > 0
			$machine[0].style[transformStyleName] = "scale(#{scaleValue})" if $machine.length > 0

	removeSharetools = ->
		$('.bbc-sharetools').remove()

	fullscreenMethod = ->

	class FullscreenManager
		_isFullscreen: false

		enter: ->
			methodName = @_method().enter
			window.document.documentElement[methodName]()
			@_isFullscreen = true

		exit: ->
			methodName = @_method().exit
			window.document[methodName]()
			@_isFullscreen = false

		isSupported: ->
			@_method()?

		isFullscreen: ->
			@_isFullscreen

		_method: ->
			docEl   = document.documentElement
			methods = [
				{
					enter: 'requestFullscreen',
					exit : 'exitFullscreen'
				},
				{
					enter: 'mozRequestFullScreen'
					exit : 'mozCancelFullScreen'
				},
				{
					enter: 'webkitRequestFullScreen',
					exit : 'webkitCancelFullScreen'
				}
			]

			method = _.find(
						methods, 
						(item) ->
							return docEl[item.enter]?
					)

			return method


	fullscreenManager = new FullscreenManager()

	toggleFullscreen = ->
		return unless fullscreenManager.isSupported()

		fullscreenManager.enter() unless fullscreenManager.isFullscreen()
		fullscreenManager.exit()  if fullscreenManager.isFullscreen()

	initFullscreenUi = ->
		return unless fullscreenManager.isSupported()

		isFullscreen = false

		$el = $('<div class="button fullscreen"><a href=""><span>Make fullscreen</span></a></div>')
		$el.on(
			'click', 
			(evt) -> 
				evt.preventDefault()
				toggleFullscreen()
		)

		$('.nav').addClass('has-fullscreen')
		$('.nav nav').append($el)

	isWebAudioSupported = ->
		return false if config.forceWebAudioSupportMessage
		return webkitAudioContext? || AudioContext?

	showWebAudioNotSupportedUi = ->
		tmpl = $('#unsupported-browser-template').html()
		el   = $(tmpl)
		$container = $('#demo')

		$container.append(el)

		$dialog = $container.find('.dialog')

		$container.on(
			'click',
			'.mask',
			(evt) ->
				$target = $(evt.target)

				# Close the mask and dialog if: 
				# - .close element clicked
				# - anything outside of the dialog box
				if $target.hasClass('close') || $target.has($dialog).length > 0
					initDemo()
					el.detach()
					evt.preventDefault()
		)

	initDemo = ->
		machine = $('body').attr('id')
		require([machine])

	init = ->
		logger.log('init')

		removeSharetools() unless config.useSharetools

		initScrollIntoView()

		initNavButtonUpdates()

		initScaleContent()

		# When a scrolling, check if we should toggle visibility of "scroll down" message
		initScrollDownHint()

		initFullscreenUi() if config.fullscreenButton || new RegExp(config.presentationModeQuerystring).test(window.location.search)

		initPresentationMode(Modernizr, initPresentationMode) if new RegExp(config.presentationModeQuerystring).test window.location.search

		if isWebAudioSupported()
			initDemo()
		else
			showWebAudioNotSupportedUi()

		# When an internal page link is clicked, scroll to the target
		# instead of just jumping there
		$(document).on('click', "[href^='#']", (evt) ->
			href = $(this).attr('href')
			el   = $(href)
			if el.length > 0
				scrollTo el
				evt.preventDefault()
		)

		# Use stellar when the window object scrolls
		$(window).stellar()

	$(document).ready(init) unless /no-scroll/.test window.location.hash
)