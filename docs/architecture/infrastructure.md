# Infrastructure - FloDoc Architecture

**Document**: Local Docker MVP Setup
**Version**: 1.0
**Last Updated**: 2026-01-14
**Deployment Strategy**: Option A - Local Docker Only

---

## 🏗️ Infrastructure Overview

FloDoc uses Docker Compose for local development and demonstration. This provides a consistent, isolated environment that mirrors production without requiring production infrastructure.

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                    Docker Host                          │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Rails     │  │  PostgreSQL │  │    Redis    │    │
│  │   App       │  │             │  │             │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│         │                │                │             │
│         └────────────────┼────────────────┘             │
│                          │                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Minio     │  │   MailHog   │  │   Sidekiq   │    │
│  │   (S3)      │  │   (Email)   │  │   (Jobs)    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🐳 Docker Compose Configuration

### docker-compose.yml

```yaml
version: '3.8'

services:
  # Rails Application
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
      - minio
    environment:
      # Database
      DATABASE_URL: postgresql://postgres:password@db:5432/flo_doc_development

      # Redis (Sidekiq)
      REDIS_URL: redis://redis:6379

      # Storage (Minio)
      AWS_ACCESS_KEY_ID: minioadmin
      AWS_SECRET_ACCESS_KEY: minioadmin
      AWS_REGION: us-east-1
      AWS_ENDPOINT_URL: http://minio:9000
      AWS_BUCKET_NAME: flo-doc

      # Email (MailHog)
      SMTP_ADDRESS: mailhog
      SMTP_PORT: 1025

      # Rails
      RAILS_ENV: development
      RAILS_LOG_LEVEL: info
      RAILS_SERVE_STATIC_FILES: true

      # Security
      SECRET_KEY_BASE: dev_secret_key_base_change_in_production
      JWT_SECRET_KEY: dev_jwt_secret_change_in_production

      # Feature Flags
      FLODOC_MULTITENANT: "false"
      FLODOC_PRO: "false"

    volumes:
      - .:/app
      - app_bundle:/usr/local/bundle
      - app_node_modules:/app/node_modules
    command: bundle exec foreman start -f Procfile.dev
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # PostgreSQL Database
  db:
    image: postgres:14-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: flo_doc_development
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis (Sidekiq)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  # Minio (S3-Compatible Storage)
  minio:
    image: minio/minio
    ports:
      - "9000:9000"  # API
      - "9001:9001"  # Console
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio_data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3

  # MailHog (Email Testing)
  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8025"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Sidekiq (Background Jobs)
  sidekiq:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/flo_doc_development
      REDIS_URL: redis://redis:6379
      RAILS_ENV: development
      AWS_ACCESS_KEY_ID: minioadmin
      AWS_SECRET_ACCESS_KEY: minioadmin
      AWS_ENDPOINT_URL: http://minio:9000
      AWS_BUCKET_NAME: flo-doc
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - .:/app
      - app_bundle:/usr/local/bundle
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  minio_data:
  app_bundle:
  app_node_modules:
```

---

## 🐋 Dockerfile

```dockerfile
# Dockerfile
FROM ruby:3.2-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    nodejs \
    npm \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Set working directory
WORKDIR /app

# Install Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle install --jobs 4 --retry 3

# Install Node dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Precompile assets (optional, can be done at runtime)
# RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

---

## 📁 Project Structure for Docker

```
floDoc-v3/
├── Dockerfile
├── docker-compose.yml
├── Procfile.dev
├── Gemfile
├── package.json
├── .env.example
├── init.sql (optional)
└── app/
```

---

## 🚀 Quick Start Guide

### Prerequisites
- Docker Desktop (or Docker Engine + Docker Compose)
- Git
- Terminal/Command Line

### Step 1: Clone & Setup
```bash
# Clone repository
git clone <repository-url> floDoc-v3
cd floDoc-v3

# Create environment file
cp .env.example .env
# Edit .env with your settings
```

### Step 2: Start Services
```bash
# Build and start all services
docker-compose up -d

# Or build without cache
docker-compose up -d --build

# View logs
docker-compose logs -f app
```

### Step 3: Setup Database
```bash
# Create and migrate database
docker-compose exec app bundle exec rails db:setup

# Or run migrations only
docker-compose exec app bundle exec rails db:migrate

# Seed data (optional)
docker-compose exec app bundle exec rails db:seed
```

### Step 4: Verify Installation
```bash
# Check all services are healthy
docker-compose ps

# Test application
curl http://localhost:3000/health

# Open in browser
open http://localhost:3000
```

---

## 🔧 Development Workflow

### Starting Development
```bash
# Start all services
docker-compose up -d

# View real-time logs
docker-compose logs -f app

# Run Rails console
docker-compose exec app bundle exec rails console

# Run database console
docker-compose exec db psql -U postgres -d flo_doc_development
```

### Running Tests
```bash
# Ruby tests
docker-compose exec app bundle exec rspec

# JavaScript tests
docker-compose exec app yarn test

# With coverage
docker-compose exec app bundle exec rspec --format documentation
docker-compose exec app yarn test --coverage
```

### Code Changes
```bash
# Edit files normally on your host machine
# Changes are automatically reflected in container

# Restart Rails server if needed
docker-compose restart app

# Rebuild specific service
docker-compose up -d --build app
```

### Stopping Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Stop specific service
docker-compose stop sidekiq
```

---

## 📊 Service Access Points

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Rails App | 3000 | http://localhost:3000 | Main application |
| PostgreSQL | 5432 | localhost:5432 | Database |
| Redis | 6379 | localhost:6379 | Sidekiq backend |
| Minio API | 9000 | http://localhost:9000 | S3-compatible storage |
| Minio Console | 9001 | http://localhost:9001 | Storage management |
| MailHog SMTP | 1025 | localhost:1025 | Email testing |
| MailHog Web | 8025 | http://localhost:8025 | Email inbox viewer |

---

## 🔍 Monitoring & Debugging

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f sidekiq

# Follow and tail
docker-compose logs -f --tail=100 app
```

### Check Service Health
```bash
# All services
docker-compose ps

# App health endpoint
curl http://localhost:3000/health

# Database connectivity
docker-compose exec app bundle exec rails runner "puts ActiveRecord::Base.connection.current_database"

# Redis connectivity
docker-compose exec redis redis-cli ping
```

### Access Containers
```bash
# Shell into app container
docker-compose exec app bash

# Shell into database
docker-compose exec db bash

# Shell into Redis
docker-compose exec redis sh
```

### Database Management
```bash
# Create database
docker-compose exec app bundle exec rails db:create

# Reset database
docker-compose exec app bundle exec rails db:reset

# Run specific migration
docker-compose exec app bundle exec rails db:migrate:up VERSION=20260114000001

# Rollback
docker-compose exec app bundle exec rails db:rollback
```

---

## 🎨 Email Testing

### Access MailHog Web UI
1. Open http://localhost:8025
2. Send emails from application
3. View email content, headers, and attachments

### Test Email Flow
```ruby
# Rails console
docker-compose exec app bundle exec rails console

# Send test email
CohortMailer.activated(Cohort.first).deliver_now

# Check MailHog at http://localhost:8025
```

---

## 💾 Storage Management

### Access Minio Console
1. Open http://localhost:9001
2. Login: `minioadmin` / `minioadmin`
3. View buckets and files

### Upload Files
```ruby
# In Rails console
cohort = Cohort.first
cohort.documents.attach(
  io: File.open('/path/to/file.pdf'),
  filename: 'document.pdf',
  content_type: 'application/pdf'
)
```

### View Uploaded Files
```ruby
# Get URL
url = url_for(cohort.documents.first)
puts url  # Will be http://minio:9000/flo-doc/...
```

---

## 🔄 Background Jobs (Sidekiq)

### Monitor Sidekiq
```bash
# View Sidekiq logs
docker-compose logs -f sidekiq

# Access Sidekiq Web UI (if mounted)
# Add to routes.rb:
# require 'sidekiq/web'
# mount Sidekiq::Web => '/sidekiq'
# Then visit http://localhost:3000/sidekiq
```

### Test Background Jobs
```ruby
# Rails console
docker-compose exec app bundle exec rails console

# Enqueue a job
CohortMailer.activated(Cohort.first).deliver_later

# Check Sidekiq logs
docker-compose logs -f sidekiq
```

---

## 🛠️ Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Error: "Bind for 0.0.0.0:3000 failed: port is already allocated"

# Solution: Stop conflicting services
sudo lsof -i :3000
kill <PID>

# Or change port in docker-compose.yml
ports:
  - "3001:3000"  # Host:Container
```

**2. Database Connection Failed**
```bash
# Error: "could not connect to server"

# Solution: Wait for DB to be ready
docker-compose exec db pg_isready -U postgres

# Or restart DB
docker-compose restart db
```

**3. Bundle Install Fails**
```bash
# Error: "Gem::Ext::BuildError"

# Solution: Rebuild with cache cleared
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

**4. Node Modules Missing**
```bash
# Error: "Cannot find module"

# Solution: Reinstall node modules
docker-compose exec app yarn install
```

**5. Assets Not Compiling**
```bash
# Precompile assets manually
docker-compose exec app bundle exec rails assets:precompile
docker-compose restart app
```

### Reset Everything
```bash
# WARNING: This deletes all data
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
docker-compose exec app bundle exec rails db:setup
```

---

## 📦 Production Considerations

### This is Local Docker MVP Only
**DO NOT use this setup for production**

### Production Requirements (Deferred)
- Managed database (RDS, Cloud SQL)
- Managed Redis (ElastiCache, Memorystore)
- Object storage (S3, GCS)
- Load balancer
- Auto-scaling
- Monitoring (CloudWatch, Stackdriver)
- Backup strategy
- SSL certificates
- Domain configuration

### When to Upgrade
- Management validates MVP
- Ready for production deployment
- Need high availability
- Require scaling beyond single instance
- Need compliance certifications

---

## 🔒 Security Notes

### Local Development Only
- Default credentials (minioadmin/password) are **NOT SECURE**
- No SSL/TLS encryption
- No firewall rules
- Debug mode enabled

### Before Production
- Change all default passwords
- Enable SSL/TLS
- Implement proper secrets management
- Use environment-specific configs
- Enable security headers
- Implement rate limiting
- Set up monitoring and alerting

---

## 📊 Performance Tuning

### Docker Resources
**Recommended for development**:
- CPU: 4+ cores
- RAM: 8GB+ (4GB for Docker)
- Disk: 50GB+

### Docker Desktop Settings
1. Open Docker Desktop
2. Go to Preferences → Resources
3. Set:
   - CPUs: 4
   - Memory: 8GB
   - Disk image size: 50GB

### Optimize Build Speed
```dockerfile
# Use layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .  # This layer changes frequently

# Multi-stage builds (for production)
```

---

## 🎯 Next Steps

1. **Start Development**:
   ```bash
   docker-compose up -d
   docker-compose exec app bundle exec rails db:setup
   ```

2. **Verify Installation**:
   - Visit http://localhost:3000
   - Check MailHog at http://localhost:8025
   - Check Minio at http://localhost:9001

3. **Run First Story**:
   ```bash
   docker-compose exec app bundle exec rails generate migration CreateFloDocTables
   ```

4. **Write Tests**:
   ```bash
   docker-compose exec app bundle exec rspec
   ```

---

## 📚 Related Documents

- **Tech Stack**: `docs/architecture/tech-stack.md`
- **Project Structure**: `docs/architecture/project-structure.md`
- **Story 8.0**: Infrastructure setup story in PRD

---

**Document Status**: ✅ Complete
**Deployment Strategy**: Local Docker MVP (Option A)
**Ready for**: Development and Management Demo