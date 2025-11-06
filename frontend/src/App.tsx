import {BrowserRouter as Router, Routes, Route} from "react-router-dom";
import Navbar from "./components/Navbar";
import Blog from "./pages/Blog";
import About from "./pages/About";
import Post from "./pages/Post";

function App() {
  return (
    <Router>
       <div className="app-container">
        <Navbar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Blog />} />
            <Route path="/about" element={<About />} />
            <Route path="/post/:slug" element={<Post />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App
