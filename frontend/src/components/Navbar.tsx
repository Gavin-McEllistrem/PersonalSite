import { Link } from "react-router-dom";
import "./Navbar.css";

export default function Navbar() {
  return (
    <nav className="navbar">
      <h1 className="site-title">Gavin McEllistrem</h1>
      <ul className="nav-links">
        <li><Link to="/">Blog</Link></li>
        <li><Link to="/about">About</Link></li>
      </ul>
    </nav>
  );
}
