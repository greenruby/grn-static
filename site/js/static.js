(function(){
  $.getJSON("editions.json", function(data) {
    $.each(data, function(d, v) {
      $(".letters").prepend(
        $("<li>").append(
          $("<a>").attr('href',v.link).text(d).append(
            $("<span>").addClass("date").text(v.date)
          )
        )
      );
    });
  });
}());