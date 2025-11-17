import { Link } from "react-router-dom";
import { useState } from "react";
import "./Navbar.css";

export default function MobileNav() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const toggleMobileMenu = () => {
    setMobileMenuOpen(!mobileMenuOpen);
  };

  const closeMobileMenu = () => {
    setMobileMenuOpen(false);
  };

  return (
    <div className="mobile-nav-container">
      <button
        className={`mobile-fab ${mobileMenuOpen ? 'open' : ''}`}
        onClick={toggleMobileMenu}
        aria-label="Navigation menu"
      >
        {mobileMenuOpen ? '✕' : '☰'}
      </button>

      {mobileMenuOpen && (
        <>
          <div className="mobile-menu-overlay" onClick={closeMobileMenu} />
          <div className="mobile-menu">
            <Link to="/" onClick={closeMobileMenu}>Blog</Link>
            <Link to="/about" onClick={closeMobileMenu}>About</Link>
          </div>
        </>
      )}
    </div>
  );
}
