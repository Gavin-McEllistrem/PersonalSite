import { Link } from "react-router-dom";
import type { PostListItem as PostListItemType } from "../types/post";

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
        border: "1px solid var(--bg3)",
        borderRadius: "8px",
        transition: "box-shadow 0.2s, background-color 0.2s",
        backgroundColor: "var(--bg1)",
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.boxShadow = "0 4px 12px rgba(0,0,0,0.3)";
        e.currentTarget.style.backgroundColor = "var(--bg2)";
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.boxShadow = "none";
        e.currentTarget.style.backgroundColor = "var(--bg1)";
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
            color: "var(--yellow-bright)",
            fontSize: "1.5rem",
          }}
        >
          {post.title}
        </h2>
        <p
          style={{
            margin: "0 0 1rem 0",
            color: "var(--gray)",
            fontSize: "0.9rem",
          }}
        >
          {formatDate(post.created_at)}
        </p>
        <p style={{ margin: 0, color: "var(--fg2)", lineHeight: "1.6" }}>
          {post.excerpt}
        </p>
      </Link>
    </article>
  );
}
