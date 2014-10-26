var animating = false,
    position = 0,
    detail = {};

var X_OFFSET = 50,
    Y_OFFSET = 50,
    SLIDE_WIDTH,
    SLIDE_HEIGHT;

$(function(){
    bindSearch();
    sidebarTree();

    if (!$(".slides").length)
        return;

    SLIDE_WIDTH = $(".slide").outerWidth();
    SLIDE_HEIGHT = $(".slide").outerHeight();

    positionSlides();
    bindKeys();
    bindTouch();
});

function positionSlides() {
    var initialPos = -(SLIDE_WIDTH / 2);

    if (window.location.hash) {
        position = parseInt(window.location.hash.slice(1));
        initialPos -= (SLIDE_WIDTH + X_OFFSET) * position;
    }

    $(".slide:not(.continue)").each(function(i){
        $(this).css("margin-left", initialPos);
        $(this).addClass("group-" + i);

        var yPos = (SLIDE_HEIGHT / 2) + Y_OFFSET;
        $(this).nextUntil(":not(.continue)").each(function(){
            $(this).css({
                "margin-left": initialPos,
                "margin-top": yPos
            });

            $(this).addClass("group-" + i);

            yPos += (SLIDE_HEIGHT + Y_OFFSET);
        });

        initialPos += SLIDE_WIDTH + X_OFFSET;
    });
}

function bindKeys() {
    $(document).bind("keydown", "left", function(){
        if (animating || position == 0)
            return;

        $(".slide").each(moveX(1));
    });

    $(document).bind("keydown", "right", function(){
        if (animating || position + 1 == $(".slide:not(.continue)").length)
            return;

        $(".slide").each(moveX(-1));
    });

    $(document).bind("keydown", "up", function(){
        var d = detail[position],
            group = $(".group-" + position);

        if (animating || d == 0)
            return;

        group.each(moveY(1));
    });

    $(document).bind("keydown", "down", function(){
        var d = detail[position],
            group = $(".group-" + position);

        if (animating || d + 1 == group.length)
            return;

        group.each(moveY(-1));
    });
}

function bindTouch() {
    var startX, endX;
    $(".slides").bind("touchstart", function(e){
        startX = e.originalEvent.touches[0].pageX;
    });

    $(".slides").bind("touchmove", function(e){
        endX = e.originalEvent.touches[0].pageX;
        e.preventDefault();
    });

    $(".slides").bind("touchend", function(e){
        if ((startX - endX) > 50)
            $(".slide").each(moveX(-1));
        else if ((endX - startX) > 50)
            $(".slide").each(moveX(1));
    });
}

function bindSearch() {
    $("#search").keyup(function(){
        $(".search_results").empty();

        if (!$("#search").val().length) {
            $(".search_results").hide();
            return;
        }

        var q = $("#search").val().toLowerCase(),
            matches = [];

        console.log(q, SEARCH_TAGS);
        $.each(SEARCH_TAGS, function(i, t){
            var k = t[0].toLowerCase(),
                n = t[1],
                url = t[2],
                item = "<li>" + n + "</li>";

            if (k.indexOf(q) == -1 || matches.indexOf(url) != -1)
                return;

            matches.push(url);

            if (k == q)
                $(".search_results").prepend(item);
            else
                $(".search_results").append(item);
        });

        if (matches.length == 0)
            $(".search_results").hide();
        else
            $(".search_results").show();
    });
}

function sidebarTree() {
    $("#sidebar .toc li").each(function(){
        var sub = $(this).find("ol:first");
        if (!sub.length) return;

        var toggle = document.createElement("span");
        $(toggle).addClass("toggle");

        $(this).find("ol").hide();

        function face(hover) {
            if (hover) {
                if (sub.css("display") == "none")
                    $(toggle).html("&#9660");
                else
                    $(toggle).html("&#9650")
            } else {
                if (sub.css("display") == "none")
                    $(toggle).html("&#9661");
                else
                    $(toggle).html("&#9651")
            }
        }

        $(toggle).html("&#9661;");
        $(toggle).click(function(){
            $(this).next("ol").slideToggle("fast", function(){
                face(false);
            });
        });

        $(toggle).mouseenter(function(){
            face(true);
        });

        $(toggle).mouseleave(function(){
            face(false);
        });

        $(toggle).insertAfter($(this).find("a:first"));
    });

    if ($("#sidebar .toc:nth(1) > li:contains(ol)").length == 1)
        $("#sidebar .toc:nth(1) .toggle:first").click();
}

function moveX(diff) {
    animating = true;
    position -= diff;

    if (detail[position] == undefined)
        detail[position] = 0;

    return function(){
        $(this).animate({
            "margin-left": getLeft($(this)) + ((SLIDE_WIDTH + X_OFFSET) * diff)
        }, {
            "duration": 250,
            "complete": (function(){
                animating = false;
                window.location.hash = position;
            })
        });
    };
}

function moveY(diff) {
    animating = true;
    detail[position] -= diff;
    return function(){
        $(this).animate({
            "margin-top": getTop($(this)) + ((SLIDE_HEIGHT + Y_OFFSET) * diff)
        }, {
            "duration": 250,
            "complete": (function(){
                animating = false;
            })
        });
    };
}

function getLeft(ele) {
    return parseInt(ele.css("margin-left"), 10);
}

function getTop(ele) {
    return parseInt(ele.css("margin-top"), 10);
}
