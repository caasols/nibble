# Nibble Roadmap

This roadmap merges the original refactor priorities with feature-parity insights from Ethernet Status analysis.

## Current Status

- Completed: **1**, **2**, **3**
- Missing / next in queue: **4** through **14**

## Priority Order

1. **Implement true 3-state network model (Active / Inactive / Disconnected)** *(done)*
   - Determine whether ethernet is physically up and whether default route traffic uses it.
   - Replace single boolean status with a typed state model.

2. **Replace heuristic classification with authoritative interface metadata** *(done)*
   - Prefer authoritative system metadata for medium/type classification.
   - Keep heuristics only as fallback and expose classification confidence.

3. **Fix and formalize snapshot pipeline** *(done)*
   - Build one `InterfaceSnapshot` per refresh cycle.
   - Derive `interfaces` and global status from the same snapshot.
   - Merge MAC/IP/type data consistently and deterministically.

4. **Adopt 3-state menubar icon behavior**
   - Reflect Active / Inactive / Disconnected states in iconography.
   - Preserve clear at-a-glance semantics for route-active vs merely plugged-in ethernet.

5. **Refactor `NetworkMonitor` into focused services**
   - Split responsibilities into interface provider, connection evaluator, public IP provider, and orchestrator.
   - Improve testability and reduce state coupling.

6. **Harden settings and app mode consistency**
   - Wire the macOS `Settings` scene to real preferences.
   - Keep sheet-based preferences only if intentionally duplicated.
   - Decide and document menubar-only behavior vs Dock visibility mode.

7. **Harden login-item behavior end-to-end**
   - Initialize UI from actual login-item system state.
   - Handle failures with rollback and user-visible feedback.
   - Finish macOS 12 strategy or raise minimum OS target.

8. **Remove blocking shell dependency / improve responsiveness**
   - Remove or isolate synchronous shell calls from refresh-critical paths.
   - Add throttling/debouncing to rapid network change events.

9. **Feature parity: richer per-interface details**
   - Expand details to include adapter vendor/model where possible.
   - Keep IPv4/IPv6/MAC details and add route-role/medium clarity.
   - Add copy actions for key values.

10. **Quality and release hardening**
    - Keep CI coverage strong and expand verification where needed.
    - Add release-grade signing/notarization workflow.
    - Enforce artifact hygiene checks.

11. **Localization foundation**
    - Externalize strings and establish localization workflow.
    - Add at least one non-English locale as a baseline.

12. **Privacy and transparency improvements**
    - Clearly document public IP lookup behavior (provider, cadence, opt-in/out).
    - Improve in-app disclosure for outbound-network operations.

13. **Utility action: DNS Flush**
    - Add a manual troubleshooting action to flush DNS cache.
    - Provide clear success/failure status and avoid automatic execution.

14. **Utility action: Quick Wi-Fi Refresh (off/on toggle)**
    - Add a manual action to disable and re-enable Wi-Fi to force reconnection.
    - Add safeguards: confirmation, cooldown, and warning about temporary connectivity disruption.

## Suggested Phasing

- **Phase 1 (Core correctness):** 1, 2, 3, 4
- **Phase 2 (Architecture + settings reliability):** 5, 6, 7, 8
- **Phase 3 (polish + release readiness):** 9, 10, 11, 12
- **Phase 4 (optional power-user tools):** 13, 14
