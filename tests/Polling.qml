import QtQuick
import Quickshell

// Integration check: exactly one wg0 config, up or down; never changes the VPN.
ShellRoot {
  property bool watchChurn: false
  property int listChanges: 0
  property int rowChanges: 0
  property int expectedCount: -1
  WireGuardModel { id: state }
  Connections {
    target: state.connections
    function onCountChanged() { if (watchChurn) listChanges++ }
    function onDataChanged() { if (watchChurn) rowChanges++ }
  }
  Component.onCompleted: state.refresh()
  Timer {
    interval: 1000
    running: true
    onTriggered: {
      if (state.stale || state.connections.count !== 1 || state.connections.get(0).name !== "wg0") {
        console.error("FAIL: expected exactly one wg0 config for this test")
        Qt.exit(1)
        return
      }
      expectedCount = state.activeCount
      state.applyStatus("")
      if (state.activeCount !== 0) {
        console.error("FAIL: off state not reflected")
        Qt.exit(1)
        return
      }
      state.applyStatus("wg0\n")
      if (state.activeCount !== 1) {
        console.error("FAIL: on state not reflected")
        Qt.exit(1)
        return
      }
      // Simulate a snapshot opposite to the actual current interface state.
      state.applyStatus(expectedCount === 1 ? "" : "wg0\n")
      watchChurn = true
    }
  }
  Timer {
    interval: 5000
    running: true
    onTriggered: {
      // Exactly one correction from the injected stale state is expected;
      // identical future snapshots must not notify/repaint row delegates.
      if (state.activeCount !== expectedCount || state.stale || listChanges !== 0 || rowChanges > 1) {
        console.error("row change signals:", rowChanges)
        console.error("FAIL: stale active count was not refreshed")
        Qt.exit(1)
      } else {
        console.log("PASS: polling corrected stale count using real wg interface")
        Qt.quit()
      }
    }
  }
}
