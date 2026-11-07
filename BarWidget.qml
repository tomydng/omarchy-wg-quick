import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "tomydng.wireguard"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened : false
  readonly property string summary: "WG"
  // User-provided local assets only: never fetch images from network URLs.
  readonly property string configuredIcon: String(setting("iconPath", ""))
  readonly property string localIcon: configuredIcon.startsWith("file:///") ? configuredIcon : ""
  readonly property bool hasIcon: icon.status === Image.Ready
  readonly property string tunnelLabel: String(setting("wg0Label", "Home VPN")).slice(0, 80).replace(/[<>]/g, "")
  readonly property real openPanelIndicatorWidth: hasIcon ? Style.bar.iconSize : button.labelWidth
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
    text: root.hasIcon ? "" : root.summary
    labelVisible: !root.hasIcon
    fixedWidth: root.hasIcon ? Style.bar.iconSlot : -1
    hasVisualContent: true
    active: !model.stale && model.activeCount > 0
    activeColor: Color.accent
    dimmed: model.stale || model.activeCount === 0
    Image {
      id: icon
      anchors.centerIn: parent
      width: Style.bar.iconSize
      height: Style.bar.iconSize
      sourceSize.width: 64
      sourceSize.height: 64
      source: root.localIcon
      fillMode: Image.PreserveAspectFit
      visible: root.hasIcon
      smooth: true
      mipmap: true
    }
    Rectangle {
      visible: root.hasIcon && button.active
      width: Style.space(4)
      height: width
      radius: width / 2
      color: Color.accent
      anchors.right: icon.right
      anchors.bottom: icon.bottom
    }
    tooltipText: model.stale ? "WireGuard: status unavailable" : (model.activeCount > 0 ? "WireGuard: " + model.activeCount + " active (interface up) · " + root.tunnelLabel : "WireGuard: off · " + root.tunnelLabel)
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.MiddleButton) model.refresh()
    }
  }
}
