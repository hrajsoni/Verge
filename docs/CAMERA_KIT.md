# Camera Kit (Phase 0 / Phase 10)

Camera Kit is an **early** technical milestone, not a late add-on. Do not wait until chat and matching are finished to prove it on real devices.

Be-Snap owns the camera UI. Camera Kit provides the Lens/AR layer only.

## Access checklist

1. Create a Snap developer account.
2. Contact Snap through the commercial/developer channel for Camera Kit.
3. Submit Be-Snap product information and confirm licensing terms.
4. Register the Android application.
5. Obtain the API token associated with the app.
6. Install Lens Studio and ship ~10–15 launch Lenses (not hardcoded effects).
7. Build a tiny internal proof of concept: preview + one Lens + photo + video.
8. Only then integrate into `feature:camera`.

## Architecture

```
Be-Snap camera UI (Compose)
        │
   Camera Kit session (API token)
        │
   Lens catalog from backend
        │
   Capture / record → media pipeline → Snap/photo/video message
```

Store the API token in `android/local.properties` or a CI secret. Never commit it.

```
CAMERAKIT_API_TOKEN=replace-me
```

The Android Camera Kit dependency lives only in `feature:camera`.
