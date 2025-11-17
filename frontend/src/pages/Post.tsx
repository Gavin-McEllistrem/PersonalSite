import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import type { Post as PostType } from "../types/post";

export default function Post() {
  const { slug } = useParams<{ slug: string }>();
  const [post, setPost] = useState<PostType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (slug) {
      fetchPost(slug);
    }
  }, [slug]);

  const fetchPost = async (slug: string) => {
    try {
      setLoading(true);
      const response = await fetch(`/api/posts/${slug}`);

      if (!response.ok) {
        throw new Error("Failed to fetch post");
      }

      const data = await response.json();
      setPost(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "An error occurred");
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  if (loading) {
    return (
      <div style={{ maxWidth: "700px", margin: "0 auto", textAlign: "center" }}>
        <p style={{ color: "var(--fg2)" }}>Loading post...</p>
      </div>
    );
  }

  if (error || !post) {
    return (
      <div style={{ maxWidth: "700px", margin: "0 auto", textAlign: "center" }}>
        <p style={{ color: "var(--red-dim)" }}>Error: {error || "Post not found"}</p>
        <Link to="/" style={{ color: "var(--blue-bright)", textDecoration: "none" }}>Back to Blog</Link>
      </div>
    );
  }

  return (
    <article style={{ maxWidth: "700px", margin: "0 auto" }}>
      <Link to="/" style={{ textDecoration: "none", color: "var(--gray)", fontSize: "0.9rem" }}>
        ← Back to Blog
      </Link>

      <h1 style={{ marginTop: "1rem", color: "var(--fg0)" }}>{post.title}</h1>

      <p style={{ color: "var(--gray)", fontSize: "0.9rem" }}>
        {formatDate(post.created_at)}
      </p>

      <div
        style={{ lineHeight: "1.8", marginTop: "2rem", textAlign: "left", color: "var(--fg1)" }}
        className="markdown-content"
      >
        <ReactMarkdown>{post.content}</ReactMarkdown>
      </div>
    </article>
  );
}
