# WireGuard (wg-quick) for the Omarchy bar

A small Omarchy Quattro bar widget for existing `/etc/wireguard/*.conf` profiles.
**No NetworkManager import, no passwordless sudo, no background root access.**

Plugin ID: `tomydng.wireguard`. MIT-licensed fork of
[Alan Sanchez's WireGuard Manager](https://github.com/alansnchz0/omarchy-wireguard-manager),
upstream commit `e61e5dd3693bfcec9ea2d65aeab2893d1901cd78`.
Original copyright and license are preserved in LICENSE. This is an independent
fork, not an official WireGuard/Omarchy project or a security-audited product.

## Features

- One shared state model for the bar and popup, refreshed every two seconds.
- Accent-colored WG button while a configured interface exists; dimmed when off.
- Stable rows, scrollable popup and a switch for each existing profile.
- Rename the displayed `wg0` label without changing its config/interface name.
- Explicit toggles call `pkexec wg-quick up|down /etc/wireguard/<name>.conf`.
- No internet requests, private-key reads, config rewriting or automatic VPN start.

**Active means the interface exists, not a successful handshake or healthy peer.**
Profiles are not imported or edited by the widget. Names must be valid WireGuard
interface names, 1–15 characters matching `[A-Za-z0-9_=+.-]`.

## Dependencies

- Omarchy Quattro with its Quickshell shell and desktop polkit agent.
- `wireguard-tools` (`wg`, `wg-quick`), `polkit` (`pkexec`), `findutils` (`find`).
- `acl` (`setfacl`) if `/etc/wireguard` is root-only.
- A trusted, root-owned configuration in `/etc/wireguard`, mode 600.
- A `resolvconf` provider **only if your profile contains `DNS=`**. Arch's
  `systemd-resolvconf` provides integration for systemd-resolved setups. Do not
  change your DNS stack just to use this widget; follow your distribution's setup.

On Arch, install missing dependencies using your usual package manager:

```bash
sudo pacman -S --needed wireguard-tools polkit findutils acl
```

No bundled installer runs privileged commands. Read each setup command first.

## Install

```bash
omarchy plugin add https://github.com/tomydng/omarchy-wg-quick.git --yes
# Directory listing/traversal only; profile contents must stay root-only (600):
pkexec setfacl -m "u:$(id -un):rx" /etc/wireguard
omarchy plugin enable tomydng.wireguard right
```

Left click **WG** to open the panel; middle click refreshes. Use the row's switch
to connect/disconnect and authenticate in the desktop prompt when requested.
Allow up to 60 seconds for authentication. Do not start another VPN manager on
the same interface. The plugin detects profiles only; it does not create them.

Change the friendly name in plugin settings, or:

```bash
omarchy bar set tomydng.wireguard wg0Label 'Home VPN'
```

The underlying interface name is always displayed separately. Other profiles
retain their filenames. R refreshes, arrows select a row, Enter toggles it.

### Optional local icon

The default label is WG. Supply your own locally stored icon to use an image:

```bash
omarchy bar set tomydng.wireguard iconPath 'file:///absolute/path/to/icon.svg'
```

Only local `file:///` URLs are accepted; the widget never downloads icons.
An empty/invalid/unavailable image falls back to WG. The image is dimmed while
off; an active interface restores full opacity and adds a small accent dot.
Colors/aspect ratio of the supplied asset are preserved.

This repository includes **no WireGuard logo**. Users must ensure permission
to use their chosen artwork. “WireGuard” and the “WireGuard” logo are registered
trademarks of Jason A. Donenfeld; see the [trademark policy](https://www.wireguard.com/trademark-policy/).
The local icon does not imply endorsement or affiliation.

### Existing upstream plugin

If switching from the original, disable it first to avoid duplicate buttons:

```bash
omarchy plugin disable io.github.alansnchz0.wireguard-manager
```

## Update / troubleshooting

```bash
omarchy plugin update tomydng.wireguard
omarchy plugin validate ~/.config/omarchy/plugins/tomydng.wireguard
```

After updating local QML components, close/reopen the popup. If it still shows
old behavior, restart **the shell only** with `omarchy restart shell` while the
desktop is unlocked. This does not restart wg-quick or change the VPN. A live
development session retained old behavior across hot reloads; a clean shell
restart was required to verify the final build.

If status is unavailable, check directory listing permission and run
`wg show interfaces` as your user. Interface names are readable without root
on the tested Linux setup; details such as handshakes usually require root.
An unavailable read is not displayed as a confirmed disconnected state.

## Remove

```bash
omarchy plugin remove tomydng.wireguard --yes
# Optional: revoke directory listing if no other widget needs it:
pkexec setfacl -x "u:$(id -un)" /etc/wireguard
```

Removing the widget does not stop any tunnel or delete profiles. If desired,
stop a tunnel explicitly: `pkexec wg-quick down wg0`.

## Security and limitations

Like other Omarchy plugins, this code runs **unsandboxed inside the desktop shell**.
Listing/status probes are unprivileged, toggles use fixed argv (not shell command
interpolation), names are validated and displayed text is plain text. A scoped
directory ACL allows filename enumeration, not reading mode-600 private keys.
The widget never installs a sudoers rule or polkit policy.

`wg-quick` itself executes config hooks as root. Use only trusted root-owned
profiles. This plugin is **not** a security boundary against a malicious local
user who already has root access or authorization to run arbitrary root commands.
Large config directories and unusually large command output are not intended use
cases. Authentication timeout is not a transactional rollback of network state;
refresh and inspect the actual interface before retrying an interrupted action.

## Development / tests

```bash
node tests/contracts.cjs
bash tests/polling.sh
omarchy plugin validate .
```

Tests need Node.js; integration additionally needs Quickshell, `timeout`, listing
access and exactly one `wg0.conf` profile. It works with that tunnel up or down,
never toggles the real tunnel, and checks stale-snapshot correction, stable row
count and no redundant data-change notifications on identical polls. Tests also
cover name validation, safe argv, plain-text sinks and shared-state wiring.

Validated on an Omarchy desktop: active/off states, color/label, popup sizing and
stable row/switch rendering after a fresh shell start, including user confirmation
with polling enabled. Not tested on every theme, scale factor or network.
