# Re:Pair B2B Platform

## Project Structure
- `backend/`: Ruby on Rails API
- `frontend/`: React + Vite + TypeScript
- `docker-compose.yml`: Docker orchestration

## Setup

### Prerequisites
- Docker & Docker Compose (Recommended)
- OR Ruby 3.2+ & Node.js 16+ (Local)

### Running with Docker
```bash
docker-compose up --build
```

### Running Locally
**Backend:**
```bash
cd backend
bundle install
rails db:create db:migrate
rails s
```
*Note: Local development uses SQLite by default. Docker uses PostgreSQL.*

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```
*Note: Downgraded to Vite 4 to support Node 16 environment.*
