"use client";

import { useState, useEffect } from "react";
import { Sun, Moon } from "lucide-react";

export default function ThemeToggle() {
  const [theme, setTheme] = useState<string>("light");

  // Initialize theme: check localStorage, fall back to system preference
  useEffect(() => {
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme) {
      // Use saved theme if it exists
      setTheme(savedTheme);
      document.documentElement.setAttribute("data-theme", savedTheme);
    } else {
      // Detect system preference for first-time visitors
      const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      const initialTheme = systemPrefersDark ? "dark" : "light";
      setTheme(initialTheme);
      document.documentElement.setAttribute("data-theme", initialTheme);
      localStorage.setItem("theme", initialTheme);
    }
  }, []);

  // Toggle theme and update localStorage
  const toggleTheme = () => {
    const newTheme = theme === "light" ? "dark" : "light";
    setTheme(newTheme);
    document.documentElement.setAttribute("data-theme", newTheme);
    localStorage.setItem("theme", newTheme);
  };

  return (
    <button
      onClick={toggleTheme}
      className="fixed bottom-4 right-4 p-2 sm:p-3 bg-[var(--neutral)] text-[var(--foreground)] rounded-full shadow-md hover:bg-[var(--primary)] hover:text-white transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-[var(--primary)] z-50"
      aria-label={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
    >
      {theme === "light" ? (
        <Moon className="h-5 w-5 sm:h-6 sm:w-6" />
      ) : (
        <Sun className="h-5 w-5 sm:h-6 sm:w-6" />
      )}
    </button>
  );
}