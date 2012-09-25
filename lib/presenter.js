(function() {

  define(['jquery', 'scroll-events', 'jquery.viewport', 'jquery.scrollTo'], function($) {
    console.log('presenter');
    $(window).bind('scrollstart', function() {
      return console.log('START SCROLLING');
    });
    return $(window).bind('scrollstop', function() {
      var mostVisible, viewportHeight, visibleEls, windowScrollTop;
      console.log('STOP SCROLLING');
      visibleEls = $('.area:in-viewport');
      console.log('visible', visibleEls);
      if (visibleEls.length < 2) {
        return;
      }
      windowScrollTop = $(window).scrollTop();
      console.log('window.scrollTop', windowScrollTop);
      viewportHeight = $(window).height();
      console.log('viewportHeight', viewportHeight);
      mostVisible = null;
      visibleEls.each(function() {
        var height, offsetTop, viewportOffset, visibleHeight;
        console.log('------->', this);
        offsetTop = $(this).offset().top;
        viewportOffset = offsetTop - windowScrollTop;
        console.log('viewportOffset', viewportOffset, viewportOffset > 0);
        height = $(this).height();
        if (viewportOffset > 0) {
          visibleHeight = (windowScrollTop + viewportHeight) - offsetTop;
        } else {
          visibleHeight = (offsetTop + height) - windowScrollTop;
        }
        console.log('height %o, visibleHeight %o', height, visibleHeight);
        if (mostVisible == null) {
          mostVisible = {
            el: this,
            height: visibleHeight
          };
          console.log('setting mostVisible height', mostVisible != null ? mostVisible.height : void 0);
        }
        if ((mostVisible != null) && (mostVisible.height < visibleHeight)) {
          mostVisible = {
            el: this,
            height: visibleHeight
          };
          return console.log('setting mostVisible height', mostVisible != null ? mostVisible.height : void 0);
        }
      });
      console.log('mostVisible', mostVisible);
      return $.scrollTo(mostVisible.el, {
        axis: 'y',
        duration: 500
      });
    });
  });

}).call(this);
