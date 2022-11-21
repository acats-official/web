function confetti_party(sec) {
    const end = Date.now() + sec * 1000;
    const colors = ["#41af6d", "#ffffff"];
    (function frame() {
      confetti({
          particleCount: 2,
          angle: 45,
          spread: 50,
          origin: { x: 0, y:0.4 },
          colors: colors,
        });

      if (Date.now() < end) {
          requestAnimationFrame(frame);
        }
    })();
}

var clicks = 0;
var cat = true;
var aristostates = ["beaver", "cat"];
function metamorph() {
    cat = !cat

    if (++clicks % 7 == 0) confetti_party(3)

    var animal = document.getElementById("cat_beaver");
    animal.classList.remove(aristostates[!cat ? 1 : 0]);
    animal.classList.add(aristostates[cat ? 1 : 0]);
}

shown_chars = 2
full_version = "2760 VINO TINTO ESPAÑOL "
spanish_flag = "&#127466;&#127480;"
function vino_tinto_version() {
    document.getElementById("sub_version").innerHTML = full_version.substring(0, ++shown_chars);
    if (shown_chars >= full_version.length) {
        document.getElementById("sub_version").innerHTML += spanish_flag
    }

}

function tab_name_rotator() {
    var pageTitle = $("title").text();

    $(window).blur(function() {
        $("title").text("Aristobäfvers");
    });

    $(window).focus(function() {
        $("title").text(pageTitle);
    });

}
tab_name_rotator()
