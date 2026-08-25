---
name: mobile-release
description: Use for Expo/EAS mobile release, native vs OTA.
version: 1.0.0
---

# commons:mobile-release

> **TLDR**: One tag `vX.Y.Z`. Bump X = native build; bump Y or Z = OTA update. Runtime version tracks X, so OTA always lands on a compatible binary.

## Delivery decision — the version number decides

Every release is a single tag `vX.Y.Z`. The CI compares it against the highest
previous version and picks the path:

- **X increased** (major) → breaking / native change → **native build** (new binary, store review)
- **Only Y or Z changed** (minor/patch) → **OTA update** (JS bundle, no store review)

No `-ota`, `-staging`, or `-draft` suffix decides the path. The number does.

**Edge rule**: the first release of a new X is always native (`vX.0.0`), so a
binary exists for every OTA of `vX.*` to land on.

## Runtime version = the major (X)

`runtimeVersion` is the OTA compatibility fence. It must equal the major so
every OTA of `vX.*` lands on the installed `vX.0.0` binary.

- Set it as an explicit string (`"runtimeVersion": "3"`), **never** `policy: fingerprint`.
- `fingerprint` is an implicit hash of native files — it changes unpredictably
  and silently breaks OTA delivery. `appVersion` on a full `X.Y.Z` creates a new
  runtime per OTA. Neither matches the "X = fence" rule.

**The bump script owns it.** `runtimeVersion` is never edited by hand. The bump
derives the major from the new version and syncs it across every place the
binary reads it:

- `app.json` → `expo.runtimeVersion`
- `android/app/src/main/res/values/strings.xml` → `expo_runtime_version`
- `ios/<app>/Supporting/Expo.plist` → `EXUpdatesRuntimeVersion`

```sh
RUNTIME_VERSION="${NEW_VERSION%%.*}"   # major only
```

Because it equals the major, it only advances when X bumps — automatically.

If the CI runs `expo prebuild`, guard against it rewriting the native runtime
value back to `file:fingerprint`.

## Two flows — staging automatic, production manual (trg-club pattern)

Name them `deploy-staging.yml` and `deploy-production.yml`. The **flow** decides
the environment, not a tag suffix.

### `deploy-staging.yml` — automatic on push of tag `v*`
```
resolve: highest previous X vs tag X
  native (X up): eas build --profile production   # the real binary
                 eas submit → TestFlight / internal track
  ota (Y/Z):     eas update --channel staging --message <tag>
```

### `deploy-production.yml` — manual (`workflow_dispatch`, input `tag`)
Promotes the **same artifact tested in staging** — no rebuild, no republish from
source. EAS is the source of truth, resolved by the tag.
```
resolve by tag:
  native: eas build:list → find build_id for the tag
          eas submit --id <build_id> → store production   # same binary tested
  ota:    eas update:list → find update group for the tag
          eas update:republish --group <id> --channel production   # same bundle
```

## Why no rebuild between staging and production

One app, one bundle id (staging is a moment, not a separate app). So the binary
built and tested for staging is the exact one promoted to production via
`eas submit --id`. OTA promotes the same bundle via `eas update:republish`.
Guarantee is "same artifact tested", not merely "same commit".

For native, the store review (Apple/Google) is unavoidable and outside your
control. OTA production is instant (next cold start). Whether native auto-releases
after approval or waits for a manual rollout is a per-project decision.

## Checklist

- [ ] Single tag scheme `vX.Y.Z`, no path-deciding suffix
- [ ] `runtimeVersion` is an explicit major string, not `fingerprint`
- [ ] Bump script syncs `runtimeVersion` in app.json + strings.xml + Expo.plist
- [ ] `deploy-staging.yml` (auto) and `deploy-production.yml` (manual dispatch)
- [ ] Production promotes the tested artifact (`eas submit --id` / `eas update:republish`)
- [ ] First release of a new major is native (`vX.0.0`)
