# Personal Website

Full-stack personal website with React frontend and Rust backend, containerized with Docker.

## Project Structure

```
Personal Website/
├── backend/                # Rust backend (Actix-web)
│   ├── src/               # Rust source code
│   ├── Cargo.toml         # Rust dependencies
│   ├── Dockerfile         # Backend container image
│   └── .dockerignore      # Docker build exclusions
├── frontend/              # React frontend (TypeScript + Vite)
│   ├── src/               # React source code
│   ├── public/            # Static assets
│   ├── package.json       # Node dependencies
│   ├── nginx.conf         # Nginx configuration for production
│   ├── Dockerfile         # Frontend container image
│   └── .dockerignore      # Docker build exclusions
└── docker-compose.yml     # Container orchestration
```

## Architecture

**Production Setup:**
- **Nginx** (frontend container): Serves static React build and reverse proxies API requests
- **Actix-web** (backend container): Handles API requests at `/api/*`
- **Docker Network**: Both containers communicate via `app-network`

**Request Flow:**
```
User Request → Nginx (Port 80)
                ├── / → Static files (React app)
                └── /api/* → Proxy to backend:8080
```

## Prerequisites

- Docker
- Docker Compose

## Deployment

### Local Deployment

1. Navigate to project directory:
   ```bash
   cd "Personal Website"
   ```

2. Build and start containers:
   ```bash
   docker-compose up -d
   ```

3. Access the website:
   ```
   http://localhost
   ```

4. View logs:
   ```bash
   docker-compose logs -f
   ```

5. Stop containers:
   ```bash
   docker-compose down
   ```

### Remote Deployment (Debian VM)

1. Install Docker on Debian VM:
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose
   sudo systemctl enable docker
   sudo systemctl start docker
   sudo usermod -aG docker $USER
   ```

2. Copy project to VM:
   ```bash
   scp -r "Personal Website" user@your-vm-ip:/home/user/
   ```

3. SSH into VM and deploy:
   ```bash
   ssh user@your-vm-ip
   cd "Personal Website"
   docker-compose up -d
   ```

4. Configure firewall (if needed):
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp  # For HTTPS
   ```

### Production Considerations

**For HTTPS/SSL:**
- Use a reverse proxy like Caddy or add SSL certificates to nginx
- Update `docker-compose.yml` to expose port 443
- Modify `nginx.conf` to handle SSL

**Environment Variables:**
- Add `.env` file for sensitive configuration
- Update `docker-compose.yml` to use environment variables

**Persistent Data:**
- Add volumes to `docker-compose.yml` if backend needs data persistence

## Development

The current setup is optimized for production. For local development:

**Frontend:**
```bash
cd frontend
npm install
npm run dev  # Runs on http://localhost:5173
```

**Backend:**
```bash
cd backend
cargo run    # Runs on http://localhost:8080
```

## Useful Commands

```bash
# Rebuild containers after code changes
docker-compose up -d --build

# View running containers
docker ps

# Stop and remove containers
docker-compose down

# Remove all containers, networks, and images
docker-compose down --rmi all

# View backend logs
docker logs personal-website-backend

# View frontend logs
docker logs personal-website-frontend
```

## Technology Stack

**Frontend:**
- React 19
- TypeScript
- Vite
- React Router
- Nginx (production server)

**Backend:**
- Rust
- Actix-web
- Actix-CORS

**Infrastructure:**
- Docker
- Docker Compose
- Debian (target deployment OS)
