import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import ReactMarkdown from "react-markdown";

type Post = {
  id: number;
  title: string;
  slug: string;
  content: string;
};

export default function Post() {
  const { slug } = useParams();
  const [post, setPost] = useState<Post | null>(null);

  useEffect(() => {
    fetch(`/api/posts/${slug}`)
      .then(res => res.json())
      .then(setPost)
      .catch(console.error);
  }, [slug]);

  if (!post) return <p>Loading...</p>;

  return (
    <article style={{ maxWidth: "700px" }}>
      <h1>{post.title}</h1>
      <ReactMarkdown>{post.content}</ReactMarkdown>
    </article>
  );
}
