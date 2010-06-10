$(document).ready(function() {
	var els = $(".clausesDetails");
	$("a.detailsShowHideLink").click(function() {
		var el = $(this).closest("table").find(".hiddenDetails");
		if (el.is(":visible")) {
		    el.slideUp();
		    $(this).text("Show details >>");
		} else {
		    el.slideDown();
		    $(this).text("Hide details <<");
		};
        })
        $("a.cdShowHide").click(function() {
		var el = $("#cd_" + $(this).attr("cdid"));
		if (el.is(":visible")) {
		    el.slideUp();
		} else {
		    els.slideUp();
		    el.slideDown();
		};
	})
});