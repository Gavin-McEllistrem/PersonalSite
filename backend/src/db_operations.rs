use sqlx::{SqlitePool, Error};
use crate::models::{Post, CreatePost, UpdatePost, Photo, CreatePhoto, PostWithPhotos};

// ============= POST OPERATIONS =============

/// Get all posts (optionally filter by published status)
pub async fn get_all_posts(pool: &SqlitePool, published_only: bool) -> Result<Vec<Post>, Error> {
    let query = if published_only {
        "SELECT id, title, slug, content, excerpt, published, created_at, updated_at
         FROM posts WHERE published = 1 ORDER BY created_at DESC"
    } else {
        "SELECT id, title, slug, content, excerpt, published, created_at, updated_at
         FROM posts ORDER BY created_at DESC"
    };

    sqlx::query_as::<_, Post>(query)
        .fetch_all(pool)
        .await
}

/// Get a single post by slug
pub async fn get_post_by_slug(pool: &SqlitePool, slug: &str) -> Result<Post, Error> {
    sqlx::query_as::<_, Post>(
        "SELECT id, title, slug, content, excerpt, published, created_at, updated_at
         FROM posts WHERE slug = ?"
    )
    .bind(slug)
    .fetch_one(pool)
    .await
}

/// Get a single post by ID
pub async fn get_post_by_id(pool: &SqlitePool, id: i64) -> Result<Post, Error> {
    sqlx::query_as::<_, Post>(
        "SELECT id, title, slug, content, excerpt, published, created_at, updated_at
         FROM posts WHERE id = ?"
    )
    .bind(id)
    .fetch_one(pool)
    .await
}

/// Get post with its photos
pub async fn get_post_with_photos(pool: &SqlitePool, slug: &str) -> Result<PostWithPhotos, Error> {
    let post = get_post_by_slug(pool, slug).await?;
    let photos = get_photos_by_post_id(pool, post.id).await?;

    Ok(PostWithPhotos { post, photos })
}

/// Create a new post
pub async fn create_post(pool: &SqlitePool, new_post: CreatePost) -> Result<Post, Error> {
    let result = sqlx::query(
        "INSERT INTO posts (title, slug, content, excerpt, published)
         VALUES (?, ?, ?, ?, ?)"
    )
    .bind(&new_post.title)
    .bind(&new_post.slug)
    .bind(&new_post.content)
    .bind(&new_post.excerpt)
    .bind(new_post.published)
    .execute(pool)
    .await?;

    let id = result.last_insert_rowid();
    get_post_by_id(pool, id).await
}

/// Update a post
pub async fn update_post(pool: &SqlitePool, id: i64, update: UpdatePost) -> Result<Post, Error> {
    // Build dynamic query based on what fields are provided
    let mut query = "UPDATE posts SET updated_at = datetime('now')".to_string();
    let mut params: Vec<String> = Vec::new();

    if let Some(title) = &update.title {
        query.push_str(", title = ?");
        params.push(title.clone());
    }
    if let Some(slug) = &update.slug {
        query.push_str(", slug = ?");
        params.push(slug.clone());
    }
    if let Some(content) = &update.content {
        query.push_str(", content = ?");
        params.push(content.clone());
    }
    if let Some(excerpt) = &update.excerpt {
        query.push_str(", excerpt = ?");
        params.push(excerpt.clone());
    }
    if let Some(published) = update.published {
        query.push_str(", published = ?");
        params.push(if published { "1".to_string() } else { "0".to_string() });
    }

    query.push_str(" WHERE id = ?");

    let mut q = sqlx::query(&query);
    for param in params {
        q = q.bind(param);
    }
    q = q.bind(id);

    q.execute(pool).await?;

    get_post_by_id(pool, id).await
}

/// Delete a post
pub async fn delete_post(pool: &SqlitePool, id: i64) -> Result<(), Error> {
    sqlx::query("DELETE FROM posts WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}

// ============= PHOTO OPERATIONS =============

/// Get all photos for a post
pub async fn get_photos_by_post_id(pool: &SqlitePool, post_id: i64) -> Result<Vec<Photo>, Error> {
    sqlx::query_as::<_, Photo>(
        "SELECT id, post_id, filename, caption, display_order, created_at
         FROM photos WHERE post_id = ? ORDER BY display_order"
    )
    .bind(post_id)
    .fetch_all(pool)
    .await
}

/// Create a photo record
pub async fn create_photo(pool: &SqlitePool, new_photo: CreatePhoto) -> Result<Photo, Error> {
    let result = sqlx::query(
        "INSERT INTO photos (post_id, filename, caption, display_order)
         VALUES (?, ?, ?, ?)"
    )
    .bind(new_photo.post_id)
    .bind(&new_photo.filename)
    .bind(&new_photo.caption)
    .bind(new_photo.display_order)
    .execute(pool)
    .await?;

    let id = result.last_insert_rowid();

    sqlx::query_as::<_, Photo>(
        "SELECT id, post_id, filename, caption, display_order, created_at
         FROM photos WHERE id = ?"
    )
    .bind(id)
    .fetch_one(pool)
    .await
}

/// Delete a photo record
pub async fn delete_photo(pool: &SqlitePool, id: i64) -> Result<(), Error> {
    sqlx::query("DELETE FROM photos WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}
