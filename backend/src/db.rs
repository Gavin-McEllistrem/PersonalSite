use sqlx::sqlite::{SqlitePool, SqlitePoolOptions};
use sqlx::Error;

/// Initialize the SQLite database connection pool
pub async fn init_db(database_url: &str) -> Result<SqlitePool, Error> {
    // Create connection pool
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    // Run schema to create tables if they don't exist
    let schema = include_str!("../schema.sql");
    sqlx::raw_sql(schema).execute(&pool).await?;

    println!("Database initialized successfully");
    Ok(pool)
}
