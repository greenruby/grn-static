(function(){
  var now = new Date();
  var year = now.getFullYear();
  $(".letters li:not(."+year+")").hide();
  $(".show-more").on("click", function(e) {
    show = $(this).data("year");
    e.preventDefault();
    $(".letters li").hide();
    $(".letters li."+show).show();
  });
  $(window).resize(function() {
    if ($(this).width() < 768) {

    }
  });
}());
