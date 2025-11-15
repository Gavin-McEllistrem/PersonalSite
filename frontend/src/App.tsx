import {BrowserRouter as Router, Routes, Route} from "react-router-dom";
import Navbar from "./components/Navbar";
import Blog from "./pages/Blog";
import Post from "./pages/Post";
import About from "./pages/About";

function App() {
  return (
    <Router>
       <div className="app-container">
        <Navbar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Blog />} />
            <Route path="/posts/:slug" element={<Post />} />
            <Route path="/about" element={<About />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App
