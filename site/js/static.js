(function(){
  $(".letters li:nth-of-type(1n+13)").hide();
  $("#show-more").on("click", function(e) {
    e.preventDefault();
    if ($(this).data("all") == 0) {
      $(this).data("all",1).text("Only show last 12");
      $(".letters li:nth-of-type(1n+13)").show();
    } else {
      $(this).data("all",0).text("Show all");
      $(".letters li:nth-of-type(1n+13)").hide();
    }
  });
  $(window).resize(function() {
    if ($(this).width() < 768) {

    }
  });
}());
