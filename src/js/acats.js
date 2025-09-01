function confetti_party(sec) {
    emit("easter_egg", {'type':'confetti'})
    const end = Date.now() + sec * 500;
    const colors = ["#41af6d", "#ffffff"];
    (function frame() {
      confetti({
          particleCount: 3,
          angle: 45,
          spread: 10,
          origin: { x: 0, y:0.4 },
          colors: colors,
        });
      confetti({
          particleCount: 3,
          angle: 135,
          spread: 10,
          origin: { x: 1, y:0.4 },
          colors: colors,
        });

      if (Date.now() < end) {
          requestAnimationFrame(frame);
        }
    })();
}

var clicks = 0;
var confetti_threshold = 5
var cat = true;
var aristostates = ["beaver", "cat"];
function metamorph() {
    if (window.matchMedia("(min-width: 1050px)").matches) {
        spawn_bottles()
    }
    if (clicks == 0) emit("easter_egg", {'type':'metamorph'})

    cat = !cat

    if (++clicks % confetti_threshold == 0) confetti_party(3)

    var animal = document.getElementById("cat_beaver");
    animal.classList.remove(aristostates[!cat ? 1 : 0]);
    animal.classList.add(aristostates[cat ? 1 : 0]);
}

shown_chars = 2
full_version = "2760 VINO TINTO ESPAÑOL "
spanish_flag = "&#127466;&#127480;"
function vino_tinto_version(element) {
    if (shown_chars == 2) emit("easter_egg", {'type':'vino_tinto'})
    element.innerHTML = full_version.substring(0, ++shown_chars);
    if (shown_chars >= full_version.length) {
        if (shown_chars == full_version.length) emit("easter_egg", {'type':'vino_tinto_espanol'})
        element.innerHTML += spanish_flag
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

function beaver() {
    console.log(`
                                                                                    ░░░░░░░░░░░░░░░░░░░░                                                  
                                                                              ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒░░                                                
                                                                        ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░          ░░░░░░░░░░                      
                                                                      ▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░▒▒░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░                
                                                                    ▒▒▓▓▒▒▒▒▒▒▓▓▓▓▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒░░▒▒░░░░▒▒▓▓▒▒▓▓▒▒▒▒▒▒░░░░░░░░              
                                                                  ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒░░          
                                                                  ▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░▒▒▒▒▒▒▓▓██▓▓▒▒▒▒▓▓▒▒▓▓▓▓▒▒▒▒▒▒▒▒▓▓▒▒▓▓        
                                                                ░░▓▓▓▓▓▓▓▓▒▒▒▒▓▓██▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒        
                                                                ▓▓▓▓▓▓▒▒▓▓▓▓▓▓▒▒▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░        
                                                              ▒▒▓▓▓▓▓▓▓▓▓▓██▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒        
                                                              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒          
                                                            ░░▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓██▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▓▓▓▓          
                                                            ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒░░▒▒░░          
                                                            ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓██▓▓▓▓▓▓▒▒▓▓▓▓▒▒▓▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒░░░░            
                                                            ▓▓██▓▓▓▓▓▓▓▓▓▓▒▒░░▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓▒▒▒▒▓▓▒▒▓▓▓▓▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒░░              
                                                          ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒██▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▓▓▓▓▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░  ░░          
                                                          ██▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▓▓▒▒▒▒▒▒▒▒▓▓▓▓░░▒▒▓▓▒▒▒▒▒▒▓▓▓▓▒▒░░░░░░▒▒██▓▓██░░      
                                                          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒▓▓▒▒▓▓▒▒▒▒▓▓▒▒▒▒░░░░▒▒▓▓████▓▓▒▒      
                                                        ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▒▒▒▒▓▓▓▓████▓▓▓▓▓▓▓▓▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒██▓▓▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▓▓████▒▒      
                                                        ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▒▒▓▓▓▓▓▓▒▒▓▓▓▓▒▒▒▒▒▒░░░░▓▓▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒              
                                                        ▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒██▓▓▓▓██░░              
                                                        ▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▓▓██▓▓▓▓▓▓░░                
                                                      ░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░                          
                                                      ▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓░░                              
                                                    ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒                                
                                          ░░░░░░▒▒░░▒▒▒▒▒▒▒▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓░░                                  
                          ░░░░░░░░░░░░░░░░▒▒░░▒▒▒▒░░▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓                                      
              ░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒  ░░                                    
      ░░░░░░░░░░░░░░░░░░░░░░▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒██████▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒░░░░                                
          ░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒██████████▓▓▓▓▓▓▓▓▒▒▒▒▓▓██████▓▓▓▓▓▓▓▓▓▓▓▓                                
              ▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓██████▓▓▒▒░░  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓██▓▓▒▒▓▓████████▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓████░░░░                                  
                                                                                        ░░▒▒▓▓▓▓▒▒▒▒██▓▓▒▒░░                                              
`)
}
beaver()

mute = true
var audio = new Audio('content/misc/untsunts.mp3');
audio.loop = true;
function musica() {
    mute = !mute
    elem = document.getElementById('speaker-icon')
    if (mute) {
        elem.classList.remove("fa-volume-up");
        elem.classList.add("fa-volume-mute");
        audio.pause()
    } else  {
        emit("easter_egg", {'type':'music'})
        elem.classList.remove("fa-volume-mute");
        elem.classList.add("fa-volume-up");
        audio.play()
    }
}

function emit(name, props) {
    posthog.capture(name, props);
}
