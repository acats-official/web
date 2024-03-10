function emit(name, props) {
    posthog.capture(name, props);
}

shown_chars = 1
full_version = "2760 VINO TINTO ESPAÑOL "
spanish_flag = "&#127466;&#127480;"
function vino_tinto_version(element) {
    if (shown_chars == 2) emit("easter_egg", {'type':'vino_tinto_konf'})
    element.innerHTML = full_version.substring(0, ++shown_chars);
    if (shown_chars >= full_version.length) {
        if (shown_chars == full_version.length) emit("easter_egg", {'type':'vino_tinto_espanol_konf'})
        element.innerHTML += spanish_flag
    }
}
