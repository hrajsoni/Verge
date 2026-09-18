# Implementation sequence

Follow this order. Do not tangle camera, chat, and discovery.

| Phase | Focus | Status |
| --- | --- | --- |
| 0 | Product, repo, Firebase, Camera Kit access path | In progress |
| 1 | Android foundation (Compose, Hilt, design system) | In progress |
| 2 | Backend foundation (NestJS, Postgres/PostGIS, Redis) | In progress |
| 3 | Auth + short onboarding | Scaffolded |
| 4 | Profiles | Scaffolded |
| 5 | Location + discovery | Scaffolded |
| 6 | Swipe engine | UI shell |
| 7 | Matching | Domain ready |
| 8 | Chat (text + WS) | Domain ready |
| 9 | Media + Snap message type | Schema ready |
| 10 | Camera Kit POC | Blocked on Snap access |
| 11 | 10–15 Lenses | Later |
| 12 | Production camera | Later |
| 13 | Voice messages | Later |
| 14 | Voice calls | Later |
| 15 | Video calls | Later |
| 16 | Safety / moderation | Schema + modules |
| 17 | Notifications | Later |
| 18 | Admin panel | Later |
| 19 | Performance | Later |
| 20 | Security hardening | Baseline |
| 21 | Testing | Later |
| 22 | Closed beta | Later |

## Dependency rule

```
UI → Feature/ViewModel → Domain → Repository → Data/API
```

Camera and Chat stay separate systems that meet at media + conversation IDs.
