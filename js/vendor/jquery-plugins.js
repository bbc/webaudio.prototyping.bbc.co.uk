/*
	This is a shim module that loads a set of jquery plugins.
	
	This simplifies calling these plugins from the rest of the 
	codebase. Instead of requiring a long list of plugins each 
	time, we can just depend on 'jquery-plugins' which will
	load them all at once.

	Each plugin itself depends on jquery and attaches itself
	to the jQuery object.
*/
define(['vendor/scroll-events', 
		'vendor/jquery.viewport', 
		'vendor/jquery.scrollTo', 
		'vendor/jquery.easing', 
		'vendor/jquery.stellar', 
		'vendor/jquery.ba-throttle-debounce'
		],
		function () {});