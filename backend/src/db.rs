use sqlx::sqlite::{SqlitePool, SqlitePoolOptions, SqliteConnectOptions};
use sqlx::Error;
use std::str::FromStr;

/// Initialize the SQLite database connection pool
pub async fn init_db(database_url: &str) -> Result<SqlitePool, Error> {
    // Parse connection options and enable database creation
    let options = SqliteConnectOptions::from_str(database_url)?
        .create_if_missing(true);

    // Create connection pool
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(options)
        .await?;

    // Run schema to create tables if they don't exist
    let schema = include_str!("../schema.sql");
    sqlx::raw_sql(schema).execute(&pool).await?;

    println!("Database initialized successfully");
    Ok(pool)
}
