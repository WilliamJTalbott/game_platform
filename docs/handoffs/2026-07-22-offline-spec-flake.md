# Offline system spec flake — root cause & fix

## What we were working on

`spec/system/games_spec.rb`'s `[ OFFLINE ]` context (`:chrome` tag) had a
flaky test: `"shows the offline page when navigation fails"`. Goal was to
stop the flakiness — started from a proposed fix (a Selenium DevTools
`service_worker.stop_all_workers` hook), then dug into why the test was
actually unreliable, then replaced it with something less fragile.

## What's done

- **Root cause identified**: `page.driver.browser.network_conditions = { offline: true, ... }`
  (Selenium's CDP network emulation) only applies to the *page's* DevTools
  target. `app/views/pwa/service-worker.js`'s `fetch` handler runs on its
  **own separate CDP target** (service workers get their own target), so its
  `fetch(event.request)` call was not covered by the emulated offline state.
  On `page.refresh`, the SW happily proxied the request to the still-reachable
  Puma test server and returned the live page — so the test's assertion
  (`expect(page).to have_content("You're Offline")`) failed, consistently in
  local runs (not just intermittently).
- Verified this by hand with a throwaway debug spec: direct `fetch()` from
  the page context correctly failed with `net::ERR_INTERNET_DISCONNECTED`
  while "offline," but `page.refresh` still loaded fresh, live DB content.
- **Replaced the flaky test** (`spec/system/games_spec.rb`, `[ OFFLINE ]`
  context) with `"caches the offline page for use when navigation fails"`,
  which waits on `navigator.serviceWorker.ready` then asserts
  `caches.match("/offline")` resolves — i.e. proves the SW pre-caches the
  fallback page on install, without simulating a real network failure at all.
- The sibling test `"tells user when they are offline"` (client-side
  `navigator.onLine` banner) was untouched — it never depended on the
  network-emulation/SW race, since it only checks JS `online`/`offline`
  events, not an actual failed fetch.
- Confirmed clean: `[ OFFLINE ]` context passes 5/5 runs, both random seeds.
- The originally-proposed `config.after(:each, :chrome, type: :system)`
  devtools hook was added to `spec/support/capybara_drivers.rb`, then
  **removed** once the new test made it unnecessary — see Decisions below.
  `capybara_drivers.rb` is back to its pre-session state.

## What's left

- ~~3 pre-existing `:js` failures in `spec/system/games_spec.rb`~~ **RESOLVED
  2026-07-22** (later session). Root cause was the `:users_turn` factory setting
  `state.turn_index` in memory without `save!`, so the reloaded game had the
  wrong active player and the turn form/button was disabled. One `save!` fixed
  all three (plus `turns_spec.rb`). Suite is fully green.
- If a real end-to-end "browser goes offline, SW serves cached page" system
  test is ever wanted, it needs offline emulation applied to *both* the page
  target and the service worker's own CDP target (e.g. via CDP
  `Target.getTargets` + attaching network emulation per-target, or a
  browser-level/flat-session CDP command). Deliberately not pursued this
  session — see Decisions.

## Decisions made

- **Chose to weaken the offline test's guarantee rather than fix the CDP
  plumbing.** The user explicitly wanted simpler tests over chasing
  cross-target DevTools behavior. The dropped coverage (real navigation
  failure → cached page served) is now only proven indirectly (cache is
  populated + client detects offline separately); the actual serve-from-cache
  wiring in `service-worker.js` is 3 lines of standard `fetch().catch()`
  and considered low-risk to leave less directly covered.
- **Removed the `service_worker.stop_all_workers` after-hook** rather than
  keeping it as defensive cleanup — nothing in the suite currently needs it,
  and it re-introduces the same CDP-target complexity we just decided to
  avoid. If a future `:chrome` + service-worker test needs worker cleanup
  between examples, re-add it then with a concrete reason.
