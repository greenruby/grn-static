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
    $(".letters li:nth-of-type(1n+13)").hide();
    $(".letters").after(
      $("<div>").append($("<a>").
        attr("href","#").
        attr("id","showmore").
        attr("data-all",0).
        text("Show all").
        on("click", function(e) {
          e.preventDefault();
          if ($(this).data("all") == 0) {
            $(this).data("all",1).text("Only show last 12");
            $(".letters li:nth-of-type(1n+13)").show();
          } else {
            $(this).data("all",0).text("Show all");
            $(".letters li:nth-of-type(1n+13)").hide();
          }
        })
      )
    );
  });
}());
