# Authentication Overview

- The API issues JWT access tokens using PyJWT (`HS256`) with a 30 day TTL. The secret key is provided via `JWT_SECRET_KEY`. TTL and refresh cadence can be tuned with `JWT_TOKEN_TTL_DAYS` and `JWT_REFRESH_INTERVAL_DAYS` (defaults: 30 and 3).
- Each request validates the `Authorization: Bearer <token>` header. When a token is older than the refresh interval the backend transparently reissues a fresh token and returns it in the `x-new-token` response header so active users always roll forward.
- Login and sign-up responses now embed the initial token alongside the user payload so clients can persist the session immediately. A helper endpoint (`GET /users/me`) returns the current profile without exposing credentials in the URL.
- Web clients persist sessions in `window.localStorage`. All native Flutter builds persist them with `flutter_secure_storage`, keeping secrets inside platform keychains.
- When the client observes a `x-new-token` header it stores the new token and continues sending it on subsequent requests. Sessions are cleared via `AppSession.clear()` which evicts both in-memory state and the persisted copy.
