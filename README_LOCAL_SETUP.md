# DocuSeal Local Development Setup

This guide will help you set up DocuSeal locally for development and testing purposes.

## Prerequisites

Before you begin, make sure you have the following installed on your system:

### Required Software
- **Ruby 3.4.2** - Use your preferred Ruby version manager (rbenv, rvm, asdf, etc.)
- **Node.js 18** - Required for frontend assets compilation
- **Yarn** - Package manager for Node.js dependencies
- **PostgreSQL** (optional) - For production-like database setup
- **Redis** - For background job processing (Sidekiq)

### macOS Dependencies
- **Homebrew** - For installing system dependencies
- **VIPS** - For image processing
- **LibreOffice** (optional) - For document conversion if you encounter upload errors

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/CareerPlug/docuseal.git
cd docuseal
```

### 2. Install Ruby Dependencies

Make sure you're using Ruby 3.4.2:

```bash
# If using rbenv
rbenv install 3.4.2
rbenv local 3.4.2

# If using rvm
rvm install 3.4.2
rvm use 3.4.2

# If using asdf
asdf install ruby 3.4.2
asdf local ruby 3.4.2
```

Install Ruby gems:

```bash
bundle install
```

### 3. Install System Dependencies

#### macOS
```bash
# Install VIPS for image processing
brew install vips

# Install LibreOffice (optional, for document conversion)
brew install --cask libreoffice
```

### 4. Setup Database

The application uses SQLite by default for development. Create and migrate the database:

```bash
rails db:create db:migrate
```

If you prefer to use PostgreSQL for a more production-like setup:

1. Install PostgreSQL
2. Create a database
3. Update `config/database.yml` to use PostgreSQL for development
4. Run the migration commands

### 5. Install Node.js Dependencies

Make sure you're using Node.js 18:

```bash
# Check your Node version
node --version

# If you need to switch to Node 18, use your preferred version manager
# Example with nvm:
nvm install 18
nvm use 18

# Install dependencies
yarn install
```

### 6. Start the Development Servers

In separate terminal windows:

```bash
# Terminal 1: Rails server
PORT=3001 bundle exec rails s -p 3001

# Terminal 2: Webpack dev server
bundle exec ./bin/shakapacker-dev-server
```

### 7. Access the Application

Open your browser and navigate to:
- **DocuSeal**: http://localhost:3001

## Initial Setup

### 1. Create Admin Account

1. Go to http://localhost:3001
2. You'll be prompted to create the first admin account
3. Fill in the required information to set up your admin user

### 2. Upload a Document

1. Log in with your admin account
2. Click "New Form" or "Upload Document"
3. Upload a PDF document to test the system
4. If you encounter upload errors, make sure LibreOffice is installed

## Troubleshooting

### Common Issues

#### Node.js Version Issues
If you get errors during `yarn install`, ensure you're using Node.js 18:
```bash
node --version  # Should show v18.x.x
```

#### Image Processing Errors
If you encounter VIPS-related errors:
```bash
# macOS
brew install vips
```

#### Document Upload Issues
If document uploads fail, install LibreOffice:
```bash
# macOS
brew install --cask libreoffice
```

#### Database Issues
If you encounter database connection issues:
```bash
# Reset the database
rails db:drop db:create db:migrate
```

## Notes
This is a standalone DocuSeal instance, this is to more easily make customizations to the fork itself without needing to integrate with another application.
- The application runs on port 3001 by default
- All data is stored locally in SQLite database for development
- File uploads are stored in the `attachments/` directory
- This setup is for local development only.
