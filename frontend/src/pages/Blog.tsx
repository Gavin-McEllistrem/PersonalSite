import { useState, useEffect } from "react";
import { Link } from "react-router-dom";

type Post = {
  id: number;
  title: string;
  slug: string;
  content: string;
};

export default function Blog() {
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => {
    fetch("/api/posts")
      .then(res => res.json())
      .then(setPosts)
      .catch(console.error);
  }, []);

  return (
    <div>
      <h2>Blog</h2>
      {posts.map(post => (
        <Link to={`/post/${post.slug}`} key={post.id} className="post-preview">
          <h3>{post.title}</h3>
          <p>{post.content.slice(0, 150)}...</p>
        </Link>
      ))}
    </div>
  );
}
