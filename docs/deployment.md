# 🔗 URL Shortener - CoinGecko Engineering Written Assignment

The deployment only focuses on single server deployment on a Dokku instance. 

## 🚀 Deployment

Dokku provides a Heroku-like experience for deploying applications, making it easier to manage and scale your application without needing to worry about the underlying infrastructure.

To deploy your own version, follow these following steps.

### Prerequisites

- Server with Dokku installed and configured
- Git installed on your local machine.

### Deployment Steps

1. **Set Up Dokku**

   First, ensure you have a Dokku instance set up. You can follow the official [Dokku installation guide](https://dokku.com/docs/getting-started/installation//) to get started.

2. **Create a New App on Dokku**

    ```bash
    dokku apps:create url-shortener-app
    ```

3. **Create PostgreSQL and Redis Services**

    ```bash
    dokku postgres:create url-shortener-db
    dokku redis:create url-shortener-redis
    ```

4. **Link Services to Your App**

    ```bash
    dokku postgres:link url-shortener-db url-shortener-app
    dokku redis:link url-shortener-redis url-shortener-app
    ```

5. **Get Service Credentials**

   Retrieve the database URLs for PostgreSQL and Redis services:
    ```bash
    dokku postgres:info url-shortener-db
    dokku redis:info url-shortener-redis
    ```

6. **Set Environment Variables**

    Based on the retrieved service credentials, set the necessary environment variables for your application. You can retrieve the database URLs from the linked services and set them in Dokku:
    ```bash
    dokku config:set url-shortener-app RAILS_MAX_THREADS=5 \
    DB_HOST= \
    DB_PORT= \
    DB_USER= \
    DB_PASSWORD= \
    REDIS_HOST= \
    REDIS_PASSWORD= \
    REDIS_PORT= \
    SECRET_KEY_BASE=
    ```

    > **Note:**
    > The `SECRET_KEY_BASE` can be generated using `rails secret` command in your local machine.

7. **Ensure the config is Correct**

    You can refer to the set environment variables with:
    ```bash
    dokku config url-shortener-app
    ```

8. **Deploy Your Application**

    You can deploy your application using Git. First, add the Dokku remote to your local repository:
    ```bash
    git remote add dokku dokku@<your-dokku-server>:url-shortener-app
    ```

    Then, push your code to the Dokku remote:
    ```bash
    git push dokku master
    ```

9. **Sidekiq Worker**

    After deploying the application, you need to ensure that the Sidekiq worker is running. You can start the Sidekiq worker on Dokku with the following command:
  
    ```bash
    dokku ps:scale url-shortener-app web=1 worker=1
    ```    

9. **Access Your Application**
    Once the deployment is complete, you can access your application at `http://url-shortener-app.<your-dokku-server-domain>`

## 🚀 Post-Deployment Setup

Setting up SSL with Let's Encrypt is crucial for securing your application. 

Follow the steps below to enable SSL for your Dokku app.

### Setting Up SSL with Let's Encrypt

1. **Install the Let's Encrypt Plugin**

   ```bash
   sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
   ```

2. **Set Your Email for Let's Encrypt**

   Set your email address for Let's Encrypt to receive notifications about certificate renewals and other important information:

   ```bash
   dokku letsencrypt:set url-shortener-app email <your email>
   ```    
   
3. **Enable Let's Encrypt for Your App**

    ```
    dokku letsencrypt url-shortener-app
    ```

4. **Set Up Automatic Renewal**
    ```
    dokku letsencrypt:cron-job --add
    ```

5. **Verify SSL is Working**

   After setting up SSL, you can verify that your application is accessible via HTTPS by visiting `https://url-shortener-app.<your-dokku-server-domain>`