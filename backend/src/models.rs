use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Post {
    pub id: i64,
    pub title: String,
    pub slug: String,
    pub content: String,
    pub excerpt: Option<String>,
    pub published: bool,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePost {
    pub title: String,
    pub slug: String,
    pub content: String,
    pub excerpt: Option<String>,
    pub published: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdatePost {
    pub title: Option<String>,
    pub slug: Option<String>,
    pub content: Option<String>,
    pub excerpt: Option<String>,
    pub published: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Photo {
    pub id: i64,
    pub post_id: i64,
    pub filename: String,
    pub caption: Option<String>,
    pub display_order: i64,
    pub created_at: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePhoto {
    pub post_id: i64,
    pub filename: String,
    pub caption: Option<String>,
    pub display_order: i64,
}

// Response models
#[derive(Debug, Serialize)]
pub struct PostWithPhotos {
    #[serde(flatten)]
    pub post: Post,
    pub photos: Vec<Photo>,
}
