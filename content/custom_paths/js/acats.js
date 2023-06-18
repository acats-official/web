function emit(name, props) {
    posthog.capture(name, props);
}
