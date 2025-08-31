"use client";

import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-[var(--neutral)] text-[var(--foreground)] py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col items-center md:flex-row md:justify-between">
          <div className="mb-4 md:mb-0">
            <p className="text-sm font-medium">
              Skillproof: Empowering Kenyan students with real-world experience
            </p>
          </div>
          <div className="flex space-x-6">
            <Link
              href="/#about"
              className="text-sm hover:text-[var(--secondary)] transition-colors"
            >
              About
            </Link>
            <Link
              href="/contact"
              className="text-sm hover:text-[var(--secondary)] transition-colors"
            >
              Contact
            </Link>
            <Link
              href="/terms"
              className="text-sm hover:text-[var(--secondary)] transition-colors"
            >
              Terms
            </Link>
          </div>
        </div>
        <div className="mt-4 text-center text-sm text-[var(--foreground)]/70">
          &copy; {new Date().getFullYear()} Skillproof. All rights reserved.
        </div>
      </div>
    </footer>
  );
}