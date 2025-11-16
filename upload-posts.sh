#!/bin/bash

# Blog Post Upload Script
# Uploads posts from the posts/ directory to your blog API

set -e  # Exit on error

# Configuration
API_URL="${API_URL:-http://localhost:8080}"
POSTS_DIR="./posts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print colored messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to convert folder name to title
# e.g., "my-first-post" -> "My First Post"
folder_to_title() {
    local folder="$1"
    # Replace hyphens and underscores with spaces, capitalize each word
    echo "$folder" | sed 's/[-_]/ /g' | sed 's/\b\(.\)/\u\1/g'
}

# Function to create slug from folder name
# e.g., "My First Post" -> "my-first-post"
folder_to_slug() {
    local folder="$1"
    echo "$folder" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

# Function to upload a single post
upload_post() {
    local post_folder="$1"
    local post_name=$(basename "$post_folder")
    local markdown_file="$post_folder/post.md"
    local photos_dir="$post_folder/photos"

    info "Processing post: $post_name"

    # Check if markdown file exists
    if [ ! -f "$markdown_file" ]; then
        error "Markdown file not found: $markdown_file"
        return 1
    fi

    # Generate title and slug from folder name
    local title=$(folder_to_title "$post_name")
    local slug=$(folder_to_slug "$post_name")

    # Read markdown content
    local content=$(cat "$markdown_file")

    # Create excerpt (first 200 characters of content, excluding frontmatter if any)
    local excerpt=$(echo "$content" | head -c 200)

    # Escape JSON special characters in content and excerpt
    content=$(echo "$content" | jq -Rs .)
    excerpt=$(echo "$excerpt" | jq -Rs .)

    # Create post JSON
    local post_json=$(cat <<EOF
{
    "title": "$title",
    "slug": "$slug",
    "content": $content,
    "excerpt": $excerpt,
    "published": true
}
EOF
)

    # Upload post
    info "Uploading post '$title' with slug '$slug'..."
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$post_json" \
        "$API_URL/api/posts")

    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [ "$http_code" != "201" ]; then
        error "Failed to upload post (HTTP $http_code)"
        echo "$body"
        return 1
    fi

    # Extract post ID from response
    local post_id=$(echo "$body" | jq -r '.id')
    info "Post created with ID: $post_id"

    # Upload photos if photos directory exists
    if [ -d "$photos_dir" ]; then
        info "Uploading photos from $photos_dir..."
        local photo_count=0

        for photo in "$photos_dir"/*; do
            if [ -f "$photo" ]; then
                local photo_name=$(basename "$photo")
                info "  Uploading photo: $photo_name"

                # Upload photo file
                local upload_response=$(curl -s -w "\n%{http_code}" -X POST \
                    -F "file=@$photo" \
                    "$API_URL/api/upload")

                local upload_http_code=$(echo "$upload_response" | tail -n1)
                local upload_body=$(echo "$upload_response" | sed '$d')

                if [ "$upload_http_code" != "200" ]; then
                    warn "Failed to upload photo $photo_name (HTTP $upload_http_code)"
                    continue
                fi

                # Extract filename from response
                local uploaded_filename=$(echo "$upload_body" | jq -r '.filename')

                # Create photo metadata
                local photo_json=$(cat <<PHOTOJSON
{
    "post_id": $post_id,
    "filename": "$uploaded_filename",
    "caption": "$photo_name",
    "display_order": $photo_count
}
PHOTOJSON
)

                # Create photo record
                local photo_response=$(curl -s -w "\n%{http_code}" -X POST \
                    -H "Content-Type: application/json" \
                    -d "$photo_json" \
                    "$API_URL/api/photos")

                local photo_http_code=$(echo "$photo_response" | tail -n1)

                if [ "$photo_http_code" == "201" ]; then
                    info "  Photo linked to post: $uploaded_filename"
                    photo_count=$((photo_count + 1))
                else
                    warn "  Failed to create photo record (HTTP $photo_http_code)"
                fi
            fi
        done

        info "Uploaded $photo_count photo(s)"
    else
        info "No photos directory found, skipping photo upload"
    fi

    info "Successfully uploaded post: $title"
    echo ""
}

# Main script
main() {
    info "Blog Post Upload Script"
    info "API URL: $API_URL"
    info "Posts directory: $POSTS_DIR"
    echo ""

    # Check if posts directory exists
    if [ ! -d "$POSTS_DIR" ]; then
        error "Posts directory not found: $POSTS_DIR"
        exit 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Please install jq."
        exit 1
    fi

    # Find all post directories
    local post_count=0
    local success_count=0

    for post_folder in "$POSTS_DIR"/*; do
        if [ -d "$post_folder" ]; then
            post_count=$((post_count + 1))
            if upload_post "$post_folder"; then
                success_count=$((success_count + 1))
            fi
        fi
    done

    echo ""
    info "============================================"
    info "Upload complete!"
    info "Total posts: $post_count"
    info "Successfully uploaded: $success_count"
    if [ $post_count -ne $success_count ]; then
        warn "Failed: $((post_count - success_count))"
    fi
    info "============================================"
}

# Run main function
main
