use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use actix_files::Files;
use actix_cors::Cors;
use serde_json::json;
use sqlx::SqlitePool;

mod db;
mod models;
mod db_operations;
mod handlers;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize database
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:blog.db".to_string());

    let pool = db::init_db(&database_url)
        .await
        .expect("Failed to initialize database");

    println!("Starting server on 0.0.0.0:8080");

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(Cors::permissive())
            // Blog API routes
            .route("/api/posts", web::get().to(handlers::get_posts))
            .route("/api/posts", web::post().to(handlers::create_post))
            .route("/api/posts/{slug}", web::get().to(handlers::get_post))
            .route("/api/posts/{id}", web::put().to(handlers::update_post))
            .route("/api/posts/{id}", web::delete().to(handlers::delete_post))
            // Photo API routes
            .route("/api/upload", web::post().to(handlers::upload_photo))
            .route("/api/photos", web::post().to(handlers::create_photo))
            .route("/api/photos/{id}", web::delete().to(handlers::delete_photo))
            // serve frontend static files after building React
            .service(Files::new("/", "../frontend/dist")
            .index_file("index.html"))
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
