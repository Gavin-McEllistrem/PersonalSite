use actix_web::{web, HttpResponse, Responder};
use actix_multipart::Multipart;
use futures_util::stream::StreamExt as _;
use sqlx::SqlitePool;
use std::io::Write;
use crate::models::{CreatePost, UpdatePost, CreatePhoto};
use crate::db_operations;

// ============= POST HANDLERS =============

/// GET /api/posts?published=true
pub async fn get_posts(
    pool: web::Data<SqlitePool>,
    query: web::Query<std::collections::HashMap<String, String>>,
) -> impl Responder {
    let published_only = query.get("published")
        .map(|v| v == "true")
        .unwrap_or(false);

    match db_operations::get_all_posts(pool.get_ref(), published_only).await {
        Ok(posts) => HttpResponse::Ok().json(posts),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch posts"
            }))
        }
    }
}

/// GET /api/posts/:slug
pub async fn get_post(
    pool: web::Data<SqlitePool>,
    slug: web::Path<String>,
) -> impl Responder {
    match db_operations::get_post_with_photos(pool.get_ref(), &slug).await {
        Ok(post) => HttpResponse::Ok().json(post),
        Err(sqlx::Error::RowNotFound) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Post not found"
        })),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch post"
            }))
        }
    }
}

/// POST /api/posts
pub async fn create_post(
    pool: web::Data<SqlitePool>,
    new_post: web::Json<CreatePost>,
) -> impl Responder {
    match db_operations::create_post(pool.get_ref(), new_post.into_inner()).await {
        Ok(post) => HttpResponse::Created().json(post),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create post"
            }))
        }
    }
}

/// PUT /api/posts/:id
pub async fn update_post(
    pool: web::Data<SqlitePool>,
    id: web::Path<i64>,
    update: web::Json<UpdatePost>,
) -> impl Responder {
    match db_operations::update_post(pool.get_ref(), *id, update.into_inner()).await {
        Ok(post) => HttpResponse::Ok().json(post),
        Err(sqlx::Error::RowNotFound) => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Post not found"
        })),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to update post"
            }))
        }
    }
}

/// DELETE /api/posts/:id
pub async fn delete_post(
    pool: web::Data<SqlitePool>,
    id: web::Path<i64>,
) -> impl Responder {
    match db_operations::delete_post(pool.get_ref(), *id).await {
        Ok(_) => HttpResponse::NoContent().finish(),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to delete post"
            }))
        }
    }
}

// ============= PHOTO HANDLERS =============

/// POST /api/upload
/// Upload a photo file and return the filename
pub async fn upload_photo(mut payload: Multipart) -> impl Responder {
    let upload_dir = std::env::var("UPLOAD_DIR")
        .unwrap_or_else(|_| "/var/lib/personal-website/photos".to_string());

    // Create upload directory if it doesn't exist
    if let Err(e) = std::fs::create_dir_all(&upload_dir) {
        eprintln!("Failed to create upload directory: {:?}", e);
        return HttpResponse::InternalServerError().json(serde_json::json!({
            "error": "Failed to create upload directory"
        }));
    }

    while let Some(item) = payload.next().await {
        let mut field = match item {
            Ok(field) => field,
            Err(e) => {
                eprintln!("Multipart error: {:?}", e);
                return HttpResponse::BadRequest().json(serde_json::json!({
                    "error": "Invalid multipart data"
                }));
            }
        };

        // Get original filename
        let content_disposition = field.content_disposition();
        let original_filename = content_disposition
            .expect("could not unwrap content")
            .get_filename()
            .unwrap_or("upload.jpg");

        // Generate unique filename
        let uuid = uuid::Uuid::new_v4();
        let extension = std::path::Path::new(original_filename)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("jpg");
        let filename = format!("{}.{}", uuid, extension);
        let filepath = format!("{}/{}", upload_dir, filename);

        // Save file
        let mut file = match std::fs::File::create(&filepath) {
            Ok(file) => file,
            Err(e) => {
                eprintln!("Failed to create file: {:?}", e);
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to save file"
                }));
            }
        };

        // Write chunks to file
        while let Some(chunk) = field.next().await {
            let data = match chunk {
                Ok(data) => data,
                Err(e) => {
                    eprintln!("Stream error: {:?}", e);
                    return HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Failed to read file data"
                    }));
                }
            };

            if let Err(e) = file.write_all(&data) {
                eprintln!("Failed to write file: {:?}", e);
                return HttpResponse::InternalServerError().json(serde_json::json!({
                    "error": "Failed to write file"
                }));
            }
        }

        // Return success with filename
        return HttpResponse::Ok().json(serde_json::json!({
            "filename": filename,
            "url": format!("/photos/{}", filename)
        }));
    }

    HttpResponse::BadRequest().json(serde_json::json!({
        "error": "No file provided"
    }))
}

/// POST /api/photos
/// Creates a photo record (metadata only)
pub async fn create_photo(
    pool: web::Data<SqlitePool>,
    new_photo: web::Json<CreatePhoto>,
) -> impl Responder {
    match db_operations::create_photo(pool.get_ref(), new_photo.into_inner()).await {
        Ok(photo) => HttpResponse::Created().json(photo),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create photo record"
            }))
        }
    }
}

/// DELETE /api/photos/:id
pub async fn delete_photo(
    pool: web::Data<SqlitePool>,
    id: web::Path<i64>,
) -> impl Responder {
    match db_operations::delete_photo(pool.get_ref(), *id).await {
        Ok(_) => HttpResponse::NoContent().finish(),
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to delete photo"
            }))
        }
    }
}
