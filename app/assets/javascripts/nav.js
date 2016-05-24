$(function() {

  var timer; //helps to slightly debounce/throttle the scroll event
  var navHeight     = $('.page-nav').outerHeight();
  var marginOfMain  = parseInt($('main').css('margin-top'));
  var contentStart  = $('main').position().top + marginOfMain;
  var scrollCurrent = 0;
  var scrollBefore  = 0;
  var delta         = 5;

  scrollNav() // call function once on page load

  function scrollNav() {
    scrollCurrent = window.pageYOffset;

    // Make sure they scroll more than delta
    if (Math.abs(scrollBefore - scrollCurrent) <= delta) {
      return;
    }

    // scolled above the default navbar position (top of page)
    if (scrollCurrent <= contentStart) {
      $('.page-nav')
        .addClass('navbar-relative')
        .removeClass('navbar-fixed');
      $('.nav-spacer').hide();
    }
    // scrolled past the start of the navbar
    else if (scrollCurrent > contentStart) {
      $('.page-nav')
        .addClass('navbar-fixed')
        .removeClass('navbar-relative');
      $('.nav-spacer').show();
    }

    scrollBefore = scrollCurrent;
  };

  $(window).scroll(function () {

    // starts new timeout if new scroll triggered before first timeout finishes
    if (timer) {
      window.clearTimeout(timer);
    }

    timer = window.setTimeout(scrollNav(), 15); //delay of 15 ms
  });

  // Smooth scroll
  $('a').click(function(){
    if (this.innerHTML == 'Top') {
      $("html, body").animate({
        scrollTop: 0
      }, 500);
    } else if ( $( $(this).attr('href') ) ) {
      $('html, body').animate({
        scrollTop: $( $(this).attr('href') ).offset().top - navHeight
      }, 500);
    }
    return false;
  });

});
