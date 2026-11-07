import QtQuick
import Quickshell.Io
import "WireGuardModel.js" as Model

Item {
  id: root
  visible: false
  width: 0
  height: 0

  property string errorMessage: ""
  property string operationName: ""
  property string operationState: "idle"
  property string lastAction: ""
  property bool timedOut: false
  signal finished(string name, string action, bool success, string errorMessage)

  function fail(name, action, message) {
    root.errorMessage = message
    root.operationState = "idle"
    root.finished(name, action, false, message)
  }

  function toggle(record, action) {
    if (operationState !== "idle") return false
    if (!record || !Model.isValidName(record.name)) {
      errorMessage = "The selected WireGuard name is invalid."
      return false
    }
    var command = Model.toggleCommand(record.name, action)
    if (command.length !== 4) {
      errorMessage = "The selected WireGuard path is invalid."
      return false
    }
    operationName = record.name
    lastAction = action
    operationState = action === "up" ? "starting" : "stopping"
    errorMessage = "Authentication required to " + action + " " + record.name + "."
    validationProcess.command = ["/usr/bin/find", Model.configPath(record.name),
      "-maxdepth", "0", "-type", "f", "!", "-type", "l", "-name", record.name + ".conf"]
    validationProcess.running = true
    return true
  }

  Process {
    id: validationProcess
    command: []
    stderr: StdioCollector { id: validationError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        var name = root.operationName
        var action = root.lastAction
        root.fail(name, action, "The WireGuard config is missing, unreadable, or is a symlink.")
        return
      }
      process.command = Model.toggleCommand(root.operationName, root.lastAction)
      root.timedOut = false
      operationTimeout.restart()
      process.running = true
    }
  }

  Timer {
    id: operationTimeout
    interval: 60000
    repeat: false
    onTriggered: {
      if (!process.running) return
      root.timedOut = true
      process.running = false
      root.fail(root.operationName, root.lastAction, "The authenticated wg-quick action timed out.")
    }
  }

  Process {
    id: process
    command: []
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: stderrCollector; waitForEnd: true }
    onExited: function(exitCode) {
      operationTimeout.stop()
      if (root.timedOut) {
        root.timedOut = false
        return
      }
      var name = root.operationName
      var action = root.lastAction
      var ok = exitCode === 0
      if (ok) {
        root.errorMessage = ""
        root.operationState = "idle"
      } else {
        var failure = stderrCollector.text && stderrCollector.text.trim()
          ? stderrCollector.text.trim()
          : (exitCode === 126 || exitCode === 127
            ? "Authentication was canceled or denied, or wg-quick is unavailable."
            : "The authenticated wg-quick action failed (exit " + exitCode + ").")
        root.fail(name, action, failure)
        return
      }
      root.finished(name, action, ok, root.errorMessage)
    }
  }
}
