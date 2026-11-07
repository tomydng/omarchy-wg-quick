import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "tomydng.wireguard"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened : false
  readonly property string summary: "WG"
  readonly property string tunnelLabel: String(setting("wg0Label", "Home VPN")).slice(0, 80).replace(/[<>]/g, "")
  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.settings = root.settings
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.stateModel = model
  }
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function togglePanel() { toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  WireGuardModel { id: model }
  Component.onCompleted: model.refresh()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "" : root.summary
    labelVisible: !root.vertical
    hasVisualContent: true
    active: !model.stale && model.activeCount > 0
    activeColor: Color.accent
    dimmed: model.stale || model.activeCount === 0
    tooltipText: model.stale ? "WireGuard: status unavailable" : (model.activeCount > 0 ? "WireGuard: " + model.activeCount + " active (interface up) · " + root.tunnelLabel : "WireGuard: off · " + root.tunnelLabel)
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.MiddleButton) model.refresh()
    }
  }
}
