use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use actix_files::Files;
use actix_cors::Cors;
use serde_json::json;


#[get("/api/hello")]
async fn hello() -> impl Responder {
    HttpResponse::Ok().json(json!({"message": "Hello from Actix!"}))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("Starting server on 0.0.0.0:8080");
    HttpServer::new(move || {
        App::new()
            .wrap(Cors::permissive())
            .service(hello)
            // serve frontend static files after building React
            .service(Files::new("/", "../frontend/dist")
            .index_file("index.html"))
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
