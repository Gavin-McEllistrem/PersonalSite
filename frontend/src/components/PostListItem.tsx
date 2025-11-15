import { Link } from "react-router-dom";
import { PostListItem as PostListItemType } from "../types/post";

interface PostListItemProps {
  post: PostListItemType;
}

export default function PostListItem({ post }: PostListItemProps) {
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  return (
    <article
      style={{
        padding: "1.5rem",
        border: "1px solid #e0e0e0",
        borderRadius: "8px",
        transition: "box-shadow 0.2s",
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.boxShadow = "0 4px 12px rgba(0,0,0,0.1)";
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.boxShadow = "none";
      }}
    >
      <Link
        to={`/posts/${post.slug}`}
        style={{
          textDecoration: "none",
          color: "inherit",
        }}
      >
        <h2
          style={{
            margin: "0 0 0.5rem 0",
            color: "#333",
            fontSize: "1.5rem",
          }}
        >
          {post.title}
        </h2>
        <p
          style={{
            margin: "0 0 1rem 0",
            color: "#666",
            fontSize: "0.9rem",
          }}
        >
          {formatDate(post.created_at)}
        </p>
        <p style={{ margin: 0, color: "#555", lineHeight: "1.6" }}>
          {post.excerpt}
        </p>
      </Link>
    </article>
  );
}
