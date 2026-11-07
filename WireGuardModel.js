.pragma library

var NAME_PATTERN = /^[A-Za-z0-9_=+.-]{1,15}$/
var CONFIG_DIR = "/etc/wireguard"

function isValidName(name) {
    return NAME_PATTERN.test(String(name || ""))
}

function parseFindOutput(raw) {
    var names = []
    var lines = String(raw || "").split(/\r?\n/)
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line || !line.endsWith(".conf")) continue
        var name = line.substring(0, line.length - 5)
        if (isValidName(name) && names.indexOf(name) === -1) names.push(name)
    }
    names.sort()
    return names
}

function parseInterfaces(raw) {
    var active = {}
    var tokens = String(raw || "").trim().split(/\s+/)
    if (tokens.length === 1 && tokens[0] === "") return active
    for (var i = 0; i < tokens.length; i++) {
        if (isValidName(tokens[i])) active[tokens[i]] = true
    }
    return active
}

function configPath(name) {
    if (!isValidName(name)) return ""
    return CONFIG_DIR + "/" + name + ".conf"
}

function discoveryCommand() {
    return ["/usr/bin/find", CONFIG_DIR, "-maxdepth", "1", "-type", "f", "-name", "*.conf", "-printf", "%f\\n"]
}

function statusCommand() {
    return ["/usr/bin/wg", "show", "interfaces"]
}

function toggleCommand(name, action) {
    if ((action !== "up" && action !== "down") || !isValidName(name)) return []
    var path = configPath(name)
    if (!path) return []
    return ["/usr/bin/pkexec", "/usr/bin/wg-quick", action, path]
}

function expectedState(action) {
    return action === "up" ? "active" : "inactive"
}
