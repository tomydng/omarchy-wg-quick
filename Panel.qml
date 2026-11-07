import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "tomydng.wireguard"
  ipcTarget: "tomydng.wireguard"
  property var anchorItem: null
  property var hostWidget: null
  property var stateModel: null
  property int selectedIndex: 0
  readonly property var barIdentity: hostWidget || root
  function displayName(name) {
    return name === "wg0" ? String(setting("wg0Label", "Home VPN")).slice(0, 80) : name
  }

  function open() {
    controller.show()
    if (stateModel) stateModel.refresh()
  }
  function toggleRecord(index) {
    if (!stateModel || stateModel.stale || runner.operationState !== "idle") return
    var record = stateModel.connections.get(index)
    if (!record || !record.known ||
        (record.operationState !== "idle" && record.operationState !== "error")) return
    var action = record.active ? "down" : "up"
    if (runner.toggle(record, action))
      stateModel.markOperation(record.name, action === "up" ? "starting" : "stopping")
  }

  WireGuardPrivilegedRunner {
    id: runner
    onFinished: function(name, action, success, errorMessage) {
      if (!root.stateModel) return
      root.stateModel.operationError = success ? "" : errorMessage.slice(0, 1000)
      root.stateModel.markOperation(name, success ? "idle" : "error")
      root.stateModel.refresh()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: popup.fittedContentWidth(Style.space(360))
    // Include BOTH margins; otherwise the popup is shorter than its contents.
    contentHeight: popup.fittedContentHeight(content.implicitHeight + Style.space(32), Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(text) {
        if ((text === "r" || text === "R") && root.stateModel) root.stateModel.refresh()
      }
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.selectedIndex = Math.max(0, Math.min(connectionRows.count - 1, root.selectedIndex + dy))
      }
      onActivateRequested: if (connectionRows.count > 0) root.toggleRecord(root.selectedIndex)

      Flickable {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: content
          width: parent.width
          spacing: Style.space(12)

          Text {
            text: "WireGuard"
            textFormat: Text.PlainText
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            Layout.fillWidth: true
            text: !root.stateModel || root.stateModel.stale ? "Status unavailable" :
              root.stateModel.activeCount > 0 ? root.stateModel.activeCount + " active tunnel(s)" : "VPN is off"
            textFormat: Text.PlainText
            color: root.stateModel && !root.stateModel.stale && root.stateModel.activeCount > 0 ? Color.accent : root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            wrapMode: Text.Wrap
          }
          PanelSeparator { foreground: root.barForeground }

          Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.stateModel ? (root.stateModel.errorMessage || root.stateModel.operationError) : ""
            textFormat: Text.PlainText
            color: Color.urgent
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WrapAnywhere
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)
          Repeater {
            id: connectionRows
            model: root.stateModel ? root.stateModel.connections : null
            delegate: Rectangle {
              required property int index
              required property string name
              required property bool active
              required property bool known
              required property string operationState
              Layout.fillWidth: true
              implicitHeight: Style.space(68)
              radius: Style.cornerRadius
              color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.05)
              border.width: 1
              border.color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, root.selectedIndex === index ? 0.3 : 0.12)

              RowLayout {
                anchors.fill: parent
                anchors.margins: Style.space(10)
                spacing: Style.space(12)
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Style.space(4)
                  Text {
                    Layout.fillWidth: true
                    text: root.displayName(name)
                    textFormat: Text.PlainText
                    color: root.barForeground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                    elide: Text.ElideRight
                  }
                  Text {
                    Layout.fillWidth: true
                    text: runner.operationName === name && runner.operationState !== "idle" ? "Waiting for authentication / applying…" :
                      name + " · " + (!known || !root.stateModel || root.stateModel.stale ? "Unknown" : active ? "Interface up" : "Disconnected")
                    textFormat: Text.PlainText
                    color: active ? Color.accent : root.barForeground
                    opacity: 0.75
                    font.family: Style.font.family
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                  }
                }
                ToggleSwitch {
                  // Avoid competing nested hover/cursor surfaces around the row.
                  cursorRing: false
                  checked: active
                  busy: runner.operationState !== "idle"
                  interactive: known && root.stateModel && !root.stateModel.stale && runner.operationState === "idle"
                  foreground: root.barForeground
                  accent: Color.accent
                  onToggled: root.toggleRecord(index)
                  Accessible.name: (active ? "Disable " : "Enable ") + name
                }
              }
            }
          }
          }
          Text {
            Layout.fillWidth: true
            visible: connectionRows.count === 0
            text: "No profiles in /etc/wireguard."
            textFormat: Text.PlainText
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.Wrap
          }
          Text {
            Layout.fillWidth: true
            text: "wg-quick · authentication may be required\nInterface up does not guarantee a peer handshake."
            textFormat: Text.PlainText
            color: root.barForeground
            opacity: 0.6
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.Wrap
          }
        }
      }
    }
  }
}
