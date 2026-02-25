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

## 🚀 Getting Started

### Prerequisites

- Ruby 3.4.8+
- PostgreSQL 16.2+
- Redis 7.2.4+
- Docker & Docker Compose (Optional, for containerized development)

> **Note:** 
> 
> For local development, you can either set up PostgreSQL and Redis manually or use Docker Compose with the provided `docker-compose.dev.yml` file.

### Installation Steps

1. **Clone the Repository**
    ```bash
    git clone https://github.com/kyleong/url-shortener.git
    cd url-shortener
    ```

2. **Set Up Environment Variables**
    Create a `.env` file in the root directory based on the `.env.example`

    ```bash
    cp .env.example .env
    ```

    Fill in the required values in the `.env` file.

    > **Tips:** 
    >
    > If using Docker, you can use the same credentials as defined in the `.env.example` file and change the `DB_PASSWORD` and `REDIS_PASSWORD`.
    >
    > For local development, ensure your PostgreSQL and Redis instances are running and accessible with the credentials you provide.

3. **Set Up Docker (Optional)**
    If you prefer using Docker, start the postgres and redis services with:

    ```bash
    docker-compose -f docker-compose.dev.yml up -d
    ```

    This will start PostgreSQL and Redis containers with the configurations specified in the `docker-compose.dev.yml` file.
    
    > **NOTE:** 
    >
    > Skip this step if you have PostgreSQL and Redis set up locally.

4. **Install Dependencies**
    ```bash
    bundle install
    ```

5. **Set Up the Database**
    ```bash
    rails db:create
    rails db:migrate
    ```

6. **Start the Application**
    ```bash
    bin/dev
    ```
