# Ethernet Status — Complete Feature Documentation

**Original Developer:** Vikram Rao (`contact@vikramrao.in`, `vikramrao.in`)
**Platform:** macOS (Mac App Store)
**App Store ID:** `id1186187538` — `https://itunes.apple.com/us/app/ethernet-status/id1186187538`
**Privacy Policy Last Updated:** 19 October 2019
**Status:** Abandonware

---

## 1. Core Purpose

macOS has a built-in Wi-Fi status icon in the menu bar, but **provides no equivalent icon for wired ethernet**. Ethernet Status fills this gap by adding a menubar icon that mirrors ethernet connection state in real time — much like the Wi-Fi icon does for wireless. The app is a pure status/monitoring utility: it has no ads, no bloatware, and no network-modifying capabilities.

---

## 2. Menubar Icon — The Three States

This is the central UX element of the app. The icon lives in the macOS menubar at all times and changes its appearance based on the current ethernet state. There are exactly three states:

| State | Icon Description | Meaning |
|---|---|---|
| **Active** | Dark `<•••>` (angle brackets with three filled dots, full opacity) | Ethernet is connected AND currently the primary/active network interface carrying traffic |
| **Inactive** | Lighter/greyed `<!>` variant (angle brackets with exclamation mark) | Ethernet is physically connected but NOT being used for network traffic — another interface (e.g. Wi-Fi) has higher routing priority |
| **Disconnected / No Interface Found** | Faded/ghost `<•••>` (same shape but very low opacity, greyed out) | No ethernet interface detected, or cable is unplugged |

**Icon design language:** The icon is a stylised `< · · · >` shape (angle brackets enclosing dots), intentionally designed to look native and Apple-like. The app icon itself (512×512 px) uses the same angle-bracket motif with three coloured dots (green, purple, red) on a light background with gold/amber brackets.

**Menubar icon assets (from the site):**
- `logo-connected.png` (301×270) — dark, full opacity
- `logo-not-connected.png` (300×270) — has an exclamation mark `!` in the centre
- `logo-not-available.png` (301×270) — same dot layout but fully faded/greyed

---

## 3. Main Dropdown Menu — Full UI Structure

The animated screenshot (`app-screenshot.gif`, 1897×1133) shows the complete dropdown menu when the menubar icon is clicked. The menu is structured as follows:

### Summary Header (top section, non-interactive)

```
Ethernet: Connected
● Active: Yes         ← green dot indicator
Public IP Address: 180.151.108.72
```

This is the "at a glance" summary for the primary/active ethernet interface. It shows:
- Connection label (`Connected` / `Disconnected`)
- Active state with a coloured dot (green = active)
- The machine's current public IP address

### Interfaces Section (sub-menus, interactive)

```
Interfaces
  USB 10/100/1000 LAN (en5)     ▶
  Thunderbolt 1 (en1)           ▶
  Thunderbolt 2 (en2)           ▶
  Thunderbolt 3 (en3)           ▶
  Thunderbolt 4 (en4)           ▶
```

Each detected ethernet interface is listed by its **human-readable name** (e.g. "USB 10/100/1000 LAN") and its **BSD interface identifier** (e.g. `en5`). Each has a submenu arrow (`▶`), suggesting clicking it opens a per-interface detail panel with further information (IP addresses, MAC, etc.).

The screenshot shows five interfaces simultaneously — demonstrating true multi-interface support. The currently active interface (USB LAN in this case) appears to be listed first or highlighted.

### App Actions (bottom section)

```
✓ Open at Login       ← checkmark = currently enabled
Preferences...
★ About Ethernet Status
──────────────────
Quit
```

- **Open at Login** — toggle for launch-on-login; shows a checkmark when enabled
- **Preferences...** — opens the Preferences/Settings panel
- **About Ethernet Status** — opens the About panel (which also contains the Settings tab, per the FAQ)
- **Quit** — terminates the app

---

## 4. Features

### 4.1 Realtime Monitoring

The app monitors the ethernet connection continuously in the background and updates both the status information and the menubar icon in real time. No manual refresh is needed.

### 4.2 Network Device Info

The app surfaces hardware-level information about the ethernet adapter that is otherwise hard to obtain from standard macOS UI:
- Adapter **maker** (manufacturer/vendor)
- Adapter **model**

This is especially useful for USB and Thunderbolt adapters where the hardware identity isn't obvious.

### 4.3 Multiple Ethernet Connections Support

The app handles **more than one ethernet interface simultaneously**. All detected interfaces appear in the Interfaces submenu (see section 3 above). Each one gets its own info and status independently. This is important for power users or docked MacBooks that may have multiple adapters.

### 4.4 IP Address & Status per Device

For each ethernet interface, the app displays:
- **IPv4 address**
- **IPv6 address**
- **MAC address** (hardware address)
- **Public IP address** (the WAN/external IP as seen from the internet)

The public IP is shown in the summary header of the dropdown. There is a user-configurable option to **hide the Public IP** (see Settings section below).

### 4.5 Covers Different Types of Connections

The app detects and supports all of the following ethernet interface types:
- **Direct Ethernet Port** — built-in RJ45 jack on older Macs
- **Ethernet dongle over USB** — USB-to-ethernet adapters
- **Ethernet to Thunderbolt adapter** — Thunderbolt-to-ethernet adapters
- **VPN** — VPN connections are also detected and covered

### 4.6 Localisation (Internationalisation)

The app is localised in the following languages:
- German
- French
- Dutch
- Chinese (Simplified)
- Chinese (Traditional)
- Japanese

Additional languages were planned but the app has since been abandoned.

---

## 5. Settings / Preferences

The app has a **Settings/Preferences** panel, accessible via two routes:
1. `Preferences...` from the dropdown menu
2. `About Ethernet Status` → then navigate to the **Settings tab** within the About popup

**Known setting documented on the website:**
- **Hide/Show Public IP Address** — a checkbox in the Settings tab that controls whether the Public IP address is displayed in the dropdown menu summary header.

---

## 6. "Open at Login" / Auto-Start Behaviour

The app supports **automatic launch on system start/login**. This is toggled directly from the dropdown menu (the `Open at Login` item, which shows a checkmark when active).

**Known edge case (documented in FAQ):** In rare situations, the auto-start mechanism does not work correctly. The workaround is to manually add the app to macOS Login Items:
- Open `System Preferences` → `Users & Groups` → `Login Items` tab
- Click `+`, navigate to `/Applications`, and select `Ethernet Status.app`

This suggests the original auto-start implementation used a now-unreliable mechanism (likely a Launch Agent or SMLoginItem rather than the more robust Login Items API).

---

## 7. Active vs. Inactive State — Detailed Logic

This is a nuanced distinction that is explicitly documented in the FAQ:

- **Active** — The ethernet interface is connected AND network traffic is currently being **routed through it**. It is the highest-priority interface in the macOS network order.
- **Inactive** — The ethernet interface is physically connected, but **another interface (e.g. Wi-Fi) has higher priority** in the macOS Network Settings interface order, so traffic flows through that other interface instead. The ethernet is "connected but idle."

This distinction matters for users who want to confirm they are actually using their ethernet connection (for speed, stability, etc.) rather than just having a cable plugged in.

The routing priority is determined by the order of interfaces in `System Preferences → Network` (or `System Settings → Network` on newer macOS) — not by the app itself.

---

## 8. Full FAQ Content

**Q1: Auto start on system (re)start not working**
There have been rare situations where auto start of the app on system (re)start does not work. In those scenarios add 'Ethernet Status' to 'Login Items' by opening 'System Preferences' and selecting 'Users & Groups'. Over there select 'Login Items' tab, click + and browse to '/Applications' folder and select 'Ethernet Status' app.

**Q2: I want to hide Public IP in menu**
Open the pull down menu and select 'About Ethernet Status'. In the popup window go to 'Settings' tab and you will find a checkbox to hide or show Public IP address in menu.

**Q3: Does it detect Thunderbolt based ethernet adaptors?**
YES

**Q4: Does it support USB based ethernet adaptors/dongles?**
YES

**Q5: How to know if ethernet is connected without opening the menu?**
The menubar icon changes based on the current ethernet status — Active / Inactive / Disconnected/No interface found (see Section 2 above for icon descriptions).

**Q6: What is the difference between "Active" and "Inactive" states?**
Active state indicates that current network traffic is being routed through an ethernet interface. Inactive state indicates that the connected ethernet interface is not being used for network traffic as some other interface (Wi-Fi for example) is also connected and has a higher priority based on order configured in Network Settings.

---

## 9. User Feedback Themes (from Reviews)

- **Apple omission:** Multiple users noted that Apple's removal of a native ethernet status indicator was frustrating. The app fills an obvious gap.
- **Ease of knowing active connection:** Users with both Wi-Fi and ethernet connected specifically valued the "Active vs Inactive" distinction to confirm which interface was carrying traffic.
- **Quick IP info:** Users valued being able to see both their LAN IP and public IP at a glance from the menubar.
- **Native look:** The icon was praised for looking like an authentic Apple icon — no visual clutter.
- **No bloatware / no ads:** Explicitly praised; it's a pure utility.
- **Finicky port detection:** At least one user (with a "finicky" Mac ethernet port) used it specifically to confirm physical cable connection.

---

## 10. Contact Form (on website)

The website has a contact form with the following fields:
- **Name** (required)
- **Email** (required)
- **Type** — dropdown: `Issues With App` / `Request A Feature` / `General Enquiry`
- **Message** (required)
- reCAPTCHA verification
- **Send** button

Support email: `contact@vikramrao.in`

---

## 11. Privacy & Data Collection

Per the Privacy Policy (last updated 19 October 2019):
- The app collects **non-personal, anonymous usage data** (platform type, usage patterns, preferences) to improve quality — but only **after explicit user consent**, which can be withdrawn at any time via app settings/preferences.
- **Personal information** (name, email) is only collected if the user contacts support via the contact form or email.
- No selling, trading, or renting of personal data to third parties.
- No data directed at or collected from users under age 13.
- The app does not collect financial data or any sensitive personal identifiers.

---

## 12. Technical & Distribution Details

- **Distribution:** Mac App Store exclusively (no direct download / sideload mentioned)
- **App Store URL:** `https://itunes.apple.com/us/app/ethernet-status/id1186187538`
- **Target OS:** macOS (no iOS/iPadOS version)
- **App type:** menubar-only agent (no Dock icon, no main window — pure background service with menubar UI)
- **Website:** `https://ethernetstatus.com`
- **Copyright:** © Vikram Rao

---

## 13. Key Gaps / Things Not Documented

These are things the website hints at but does not fully specify — worth investigating for your open-source version:

- The **exact per-interface submenu contents** (what info is shown when you click the `▶` arrow on a specific interface) — likely IPv4, IPv6, MAC address per interface
- The **Preferences window** UI beyond the Public IP toggle
- The **About window** layout and version/license info
- Whether the app has **notifications** for connection changes
- The **polling interval** for realtime monitoring (how frequently it checks interface state)
- Whether it uses `SCNetworkReachability`, `SystemConfiguration`, `Network.framework`, or shell commands like `ifconfig`/`networksetup` under the hood
- Whether VPN support covers all VPN types (IKEv2, WireGuard, OpenVPN, etc.) or only system VPNs
