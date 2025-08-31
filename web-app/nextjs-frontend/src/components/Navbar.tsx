"use client";

import Image from "next/image";
import Link from "next/link";
import { useState, useEffect } from "react";

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isMounted, setIsMounted] = useState(false); // New state to track client-side mounting

  useEffect(() => {
    setIsMounted(true); // Set to true after component mounts on client
  }, []);

  return (
    <nav
      className={`bg-[var(--neutral)]/80 backdrop-blur-md shadow-sm fixed top-0 left-0 right-0 z-50`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          {/* Logo and Project Name */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center space-x-2">
              <Image
                src="/logo.png"
                alt="SkillProof Logo"
                width={1000}
                height={1000}
                priority
                className="h-10 w-auto"
              />
              <span className="text-[var(--foreground)] font-bold text-lg">
                SkillProof
              </span>
            </Link>
          </div>

          {/* Desktop Menu */}
          <div className="hidden sm:flex sm:items-center sm:space-x-8">
            <Link
              href="/#about"
              className="text-[var(--foreground)] hover:text-[var(--secondary)] font-medium transition-colors"
            >
              About
            </Link>
            <Link
              href="/auth/login"
              className="text-[var(--foreground)] hover:text-[var(--secondary)] font-medium transition-colors"
            >
              Login
            </Link>
            <Link
              href="/auth/register"
              className="bg-[var(--accent)] text-[var(--background)] px-4 py-2 rounded-full font-medium hover:bg-[oklch(75%_0.1_50)] transition-colors"
            >
              Register
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <div className="sm:hidden flex items-center">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="text-[var(--foreground)] hover:text-[var(--secondary)] focus:outline-none"
            >
              <svg
                className="h-6 w-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d={isMenuOpen ? "M6 18L18 6M6 6l12 12" : "M4 6h16M4 12h16M4 18h16"}
                />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMenuOpen && (
        <div className="sm:hidden bg-[var(--neutral)]/80 backdrop-blur-md">
          <div className="px-2 pt-2 pb-3 space-y-1">
            <Link
              href="/#about"
              className="block text-[var(--foreground)] hover:text-[var(--secondary)] px-3 py-2 font-medium"
              onClick={() => setIsMenuOpen(false)}
            >
              About
            </Link>
            <Link
              href="/auth/login"
              className="block text-[var(--foreground)] hover:text-[var(--secondary)] px-3 py-2 font-medium"
              onClick={() => setIsMenuOpen(false)}
            >
              Login
            </Link>
            <Link
              href="/auth/register"
              className="block bg-[var(--accent)] text-[var(--background)] px-3 py-2 rounded-full font-medium hover:bg-[oklch(75%_0.1_50)]"
              onClick={() => setIsMenuOpen(false)}
            >
              Register
            </Link>
          </div>
        </div>
      )}
    </nav>
  );
}