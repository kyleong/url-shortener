# 🔗 URL Shortener - CoinGecko Engineering Written Assignment

Live: https://url-shortener-app.89.167.96.36.sslip.io/

![URL Shortener Screenshot](./assets/screenshot.png)

A simple, URL Shortener service built as part of the CoinGecko Engineering Written Assignment.

## ⭐ Features

- Shorten URLs with unique short codes
- Track visits with metadata (timestamp, IP, geolocation)
- Paginated visit history for each short URL
- Background processing for metadata fetching and geolocation
- Real-time updates on visit counts and recent activity
- Mobile responsiveness and dark mode

## 🛠 Tech Stack

Backend
- Ruby on Rails — Web framework and MVC architecture
- PostgreSQL — Primary relational database
- Redis — Caching, Sidekiq, and Action Cable adapter
- Sidekiq — Background job processing for metadata fetching and geolocation
- RSpec — Testing framework

Frontend
- Tailwind CSS + DaisyUI — Utility-first styling and UI components

DevOps / Infrastructure
- Docker — Containerized development and deployment
- Dokku — Self-hosted PaaS deployment platform

## 🏗 Architecture

### High-Level Overview

![URL Shortener Architecture](./assets/architecture.png)

- Web and Worker are two separate containers from the same Dokku app, sharing the same Redis and Postgres instances.
- Web handles HTTP requests, Worker handles background jobs.
- Both connect to Redis and Postgres, hence the crossing arrows.

<details>
<summary>Click to Expand In-Depth Explanation</summary>

#### Background Jobs with Sidekiq + Redis

![URL Shortener Architecture - DB 0](./assets/architecture-db0.png)

- Browser sends a request → Controller pushes a Job to Redis **DB 0** (queue)
- Sidekiq (Worker) polls Redis, picks up the job, and reads/writes it via the Model

#### Real-time Updates with Action Cable + Redis Pub/Sub

![URL Shortener Architecture - DB 1](./assets/architecture-db1.png)

- Browser opens a WebSocket connection to Action Cable
- When a job or model update occurs, it publishes to Redis **DB 1** (Pub/Sub)
- Action Cable subscribes to Redis and pushes the update to the browser instantly

#### Caching with Redis

![URL Shortener Architecture - DB 2](./assets/architecture-db2.png)

- Browser sends a request → Controller → Model checks Redis **DB 2** first
- Cache hit → returns immediately, skips Postgres
- Cache miss → queries Postgres, stores result in Redis for next time

</details>