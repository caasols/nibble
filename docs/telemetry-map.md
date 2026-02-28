# Telemetry Data Map (Internal)

This document defines the telemetry governance contract for Nibble.

## Purpose

Telemetry is used only to improve product decisions around settings discoverability and feature adoption.

## Governance Rules

- Telemetry is opt-in and disabled by default.
- Unknown event names are rejected at enqueue time.
- Unknown payload fields are dropped at enqueue time.
- Sensitive network identifiers are never queued by default.
  - Disallowed examples: public IP, private IP, MAC address, SSID, interface name.

## Event Allowlist

The queue accepts only the events below.

| Event name | Allowed payload fields | Notes |
| --- | --- | --- |
| `app_started` | `app_mode` | App mode value (`menuBarOnly` or `menuBarAndDock`) |
| `open_preferences` | `source` | Where preferences were opened from |
| `toggle_telemetry` | `enabled` | New telemetry opt-in state (`true`/`false`) |
| `toggle_public_ip` | `enabled` | New public-IP visibility state (`true`/`false`) |

## Retention and Storage

- Pending telemetry events are stored locally in `UserDefaults` under `telemetryPendingEvents`.
- Users can erase all pending unsent telemetry data from Preferences at any time.
- Nibble does not include sensitive network identifiers in queued telemetry data.

## Aggregation Level

- Events are low-cardinality product interaction signals only.
- Payload values should remain categorical booleans/enums and must avoid free-form text.

## Enforcement Location

- `Nibble/UserDefaultsTelemetryQueueStore.swift`
  - allowlist for event names
  - allowlist for payload keys per event
  - default rejection of unknown/sensitive keys
