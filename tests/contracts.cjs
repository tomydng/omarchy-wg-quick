const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const dir = path.resolve(__dirname, '..');
const read = name => fs.readFileSync(path.join(dir, name), 'utf8');
const ctx = {};
vm.runInNewContext(read('WireGuardModel.js').replace(/^\.pragma library\s*/, ''), ctx);
assert.deepEqual(JSON.parse(JSON.stringify(ctx.parseInterfaces('wg0 wg1\n'))), { wg0: true, wg1: true });
assert.equal(Object.keys(ctx.parseInterfaces('')).length, 0);
for (const name of ['../wg0', '<img>', '$(id)', 'x;id', 'x'.repeat(16)]) {
  assert.equal(ctx.isValidName(name), false);
  assert.equal(ctx.toggleCommand(name, 'up').length, 0);
}
assert.equal(JSON.stringify(ctx.toggleCommand('wg0', 'up')),
  JSON.stringify(['/usr/bin/pkexec', '/usr/bin/wg-quick', 'up', '/etc/wireguard/wg0.conf']));
const bar = read('BarWidget.qml');
const panel = read('Panel.qml');
assert.match(bar, /panelLoader\.item\.stateModel = model/);
assert.doesNotMatch(panel, /WireGuardModel\s*\{/); // no independent stale snapshot
assert.match(bar, /dimmed: model\.stale \|\| model\.activeCount === 0/);
assert.match(bar, /activeColor: Color\.accent/);
assert.match(panel, /content\.implicitHeight \+ Style\.space\(32\)/);
assert.doesNotMatch(panel, /ListView|CursorSurface/);
assert.match(panel, /Repeater\s*\{/);
assert.match(panel, /cursorRing: false/);
// Every dynamic Text must explicitly opt out of rich text interpretation.
for (const block of panel.matchAll(/Text\s*\{([\s\S]*?)\n\s*\}/g)) {
  assert.match(block[1], /textFormat: Text\.PlainText/);
}
assert.match(bar, /replace\(/); // sanitize configurable label before shared tooltip
assert.equal(JSON.parse(read('manifest.json')).barWidget.defaults.wg0Label, 'Home VPN');
assert.equal(JSON.parse(read('manifest.json')).barWidget.defaults.iconPath, '');
assert.match(bar, /configuredIcon\.startsWith\("file:\/\/\/"\)/);
assert.match(bar, /readonly property bool hasIcon: icon\.status === Image\.Ready/);
assert.match(bar, /text: root\.hasIcon \? "" : root\.summary/);
assert.match(bar, /fillMode: Image\.PreserveAspectFit/);
assert.match(bar, /visible: root\.hasIcon && button\.active/);
console.log('PASS: parser, safe argv, shared state, colors, layout and text contracts');
