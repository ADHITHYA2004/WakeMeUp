# WakeMeUp MySQL API

Minimal Express + MySQL API for the Flutter app.

## Setup

1. Create a database in MySQL:

   ```sql
   CREATE DATABASE IF NOT EXISTS wakemeup;
   USE wakemeup;
   CREATE TABLE IF NOT EXISTS destinations (
     id INT AUTO_INCREMENT PRIMARY KEY,
     name VARCHAR(255) NOT NULL,
     latitude DOUBLE NOT NULL,
     longitude DOUBLE NOT NULL,
     created_at DATETIME NOT NULL
   );
   ```

2. Create `.env` from example:

   - DB_HOST=127.0.0.1
   - DB_PORT=3306
   - DB_USER=root
   - DB_PASSWORD=#Root1234
   - DB_NAME=wakemeup
   - PORT=4000

3. Install and run:
   ```bash
   npm install
   npm run dev
   ```

## Endpoints

- GET `/api/destinations` → list
- POST `/api/destinations` → create
- DELETE `/api/destinations/:id` → delete
