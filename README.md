# Personal Website

Full-stack personal website with React frontend and Rust backend, containerized with Docker.

## Project Structure

```
Personal Website/
├── backend/                # Rust backend (Actix-web)
│   ├── src/               # Rust source code
│   │   ├── main.rs        # Application entry point
│   │   └── db.rs          # Database initialization
│   ├── schema.sql         # SQLite database schema
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
├── docker-compose.yml     # Container orchestration (named volumes)
└── docker-compose.prod.yml # Production config (bind mounts)
```

## Architecture

**Production Setup:**
- **Nginx** (frontend container): Serves static React build and reverse proxies API requests
- **Actix-web** (backend container): Handles API requests at `/api/*`
- **SQLite** (backend): Stores blog posts and photo metadata
- **Docker Volumes**: Persist database and uploaded photos
- **Docker Network**: Both containers communicate via `app-network`

**Request Flow:**
```
User Request → Nginx (Port 80)
                ├── / → Static files (React app)
                ├── /photos/* → Uploaded photos (read-only)
                └── /api/* → Proxy to backend:8080 → SQLite DB
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

2. **Create data directories** (for production with bind mounts):
   ```bash
   sudo mkdir -p /var/lib/personal-website/photos
   sudo chown -R $USER:$USER /var/lib/personal-website
   ```

3. Copy project to VM:
   ```bash
   scp -r "Personal Website" user@your-vm-ip:/home/user/
   ```

4. SSH into VM and deploy:
   ```bash
   ssh user@your-vm-ip
   cd "Personal Website"

   # Option A: Use Docker named volumes (managed by Docker)
   docker-compose up -d

   # Option B: Use bind mounts to /var/lib/personal-website (recommended for production)
   docker-compose -f docker-compose.prod.yml up -d
   ```

5. Configure firewall (if needed):
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp  # For HTTPS
   ```

### Data Persistence

**Database location:**
- Named volumes: Managed by Docker in `/var/lib/docker/volumes/`
- Bind mounts: `/var/lib/personal-website/blog.db`

**Photo uploads:**
- Named volumes: Managed by Docker
- Bind mounts: `/var/lib/personal-website/photos/`

**Access data on VM:**
```bash
# View database
sqlite3 /var/lib/personal-website/blog.db

# List uploaded photos
ls -la /var/lib/personal-website/photos/

# Backup database
cp /var/lib/personal-website/blog.db ~/backup-$(date +%Y%m%d).db
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

## API Documentation

### Blog Posts

**Get all posts**
```http
GET /api/posts?published=true
```
Query parameters:
- `published` (optional): Filter by published status (`true` or `false`)

Response: Array of posts with metadata (no photos)

**Get single post**
```http
GET /api/posts/{slug}
```
Response: Post object with associated photos

**Create post**
```http
POST /api/posts
Content-Type: application/json

{
  "title": "My Blog Post",
  "slug": "my-blog-post",
  "content": "# Markdown content here\n\n![Photo](/photos/uuid.jpg)",
  "excerpt": "Short description",
  "published": true
}
```

**Update post**
```http
PUT /api/posts/{id}
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content",
  "published": true
}
```
All fields are optional - only include what you want to update.

**Delete post**
```http
DELETE /api/posts/{id}
```

### Photo Upload

**Upload a photo**
```http
POST /api/upload
Content-Type: multipart/form-data

file: <binary data>
```

Response:
```json
{
  "filename": "a1b2c3d4-e5f6-7890-photo.jpg",
  "url": "/photos/a1b2c3d4-e5f6-7890-photo.jpg"
}
```

Use the returned `url` in your markdown:
```markdown
![Photo caption](/photos/a1b2c3d4-e5f6-7890-photo.jpg)
```

**Create photo metadata record** (optional)
```http
POST /api/photos
Content-Type: application/json

{
  "post_id": 1,
  "filename": "uuid.jpg",
  "caption": "Beach sunset",
  "display_order": 0
}
```

**Delete photo metadata**
```http
DELETE /api/photos/{id}
```
Note: This only deletes the database record, not the file itself.

### Example Workflow

1. **Upload photo:**
   ```bash
   curl -X POST http://localhost/api/upload \
     -F "file=@beach.jpg"
   # Returns: {"url": "/photos/abc123.jpg"}
   ```

2. **Create blog post with photo:**
   ```bash
   curl -X POST http://localhost/api/posts \
     -H "Content-Type: application/json" \
     -d '{
       "title": "Beach Day",
       "slug": "beach-day",
       "content": "# Beach Day\n\n![Sunset](/photos/abc123.jpg)\n\nWhat a beautiful day!",
       "published": true
     }'
   ```

3. **View post:**
   ```bash
   curl http://localhost/api/posts/beach-day
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
- SQLx (async SQL toolkit)
- SQLite (database)

**Infrastructure:**
- Docker
- Docker Compose
- Nginx (reverse proxy & static file server)
- Debian (target deployment OS)
