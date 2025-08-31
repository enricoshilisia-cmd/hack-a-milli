"use client";

import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuthStore } from "@/hooks/useAuth";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faHome, faTasks, faUser, faSignOutAlt, faBars, faTimes } from "@fortawesome/free-solid-svg-icons";
import { useState, useEffect } from "react";
import api from "@/lib/api";
import Image from "next/image";

export default function CompNavbar() {
  const router = useRouter();
  const { logout, user, isAuthenticated } = useAuthStore();
  const [companyName, setCompanyName] = useState<string | null>(null);
  const [companyLogo, setCompanyLogo] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [isMenuOpen, setIsMenuOpen] = useState<boolean>(false);

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") return;

    const fetchCompanyProfile = async () => {
      setLoading(true);
      try {
        const response = await api.get<{ name: string; logo: string | null }>("/companies/company/profile/", {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        setCompanyName(response.data.name || user?.email || "Company Portal");
        setCompanyLogo(response.data.logo || null);
      } catch (err: unknown) {
        console.error("Failed to fetch company profile:", (err as Error).message);
        setCompanyName(user?.email || "Company Portal");
        setCompanyLogo(null);
      } finally {
        setLoading(false);
      }
    };

    fetchCompanyProfile();
  }, [isAuthenticated, user]);

  const handleLogout = () => {
    logout();
    router.push("/auth/login");
  };

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  return (
    <nav className="fixed top-0 w-full bg-[var(--accent)] text-[var(--background)] px-2 sm:px-4 py-3 shadow-md z-50">
      <div className="container mx-auto flex items-center justify-between">
        {/* Logo and Company Name */}
        <div className="flex items-center gap-2 sm:gap-3">
          {companyLogo && !loading ? (
            <Link href="/company/dashboard">
              <div className="relative w-8 h-8 sm:w-10 sm:h-10">
                <Image
                  src={companyLogo}
                  alt="Company Logo"
                  fill
                  className="object-contain"
                  onError={() => setCompanyLogo(null)}
                />
              </div>
            </Link>
          ) : (
            <Link href="/company/dashboard" className="text-[var(--background)] text-base sm:text-lg font-semibold">
              {loading ? "Loading..." : "Company Portal"}
            </Link>
          )}
          <Link href="/company/dashboard" className="text-base sm:text-lg font-bold truncate max-w-[150px] sm:max-w-[200px]">
            {loading ? "Loading..." : companyName}
          </Link>
        </div>

        {/* Hamburger Menu Button (Mobile) */}
        <button
          className="sm:hidden text-[var(--background)] focus:outline-none"
          onClick={toggleMenu}
          aria-label={isMenuOpen ? "Close menu" : "Open menu"}
        >
          <FontAwesomeIcon icon={isMenuOpen ? faTimes : faBars} size="lg" />
        </button>

        {/* Navigation Links (Desktop) */}
        <div className="hidden sm:flex items-center gap-4 sm:gap-6">
          <Link
            href="/company/dashboard"
            className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-sm sm:text-base"
          >
            <FontAwesomeIcon icon={faHome} />
            Dashboard
          </Link>
          <Link
            href="/company/challenges"
            className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-sm sm:text-base"
          >
            <FontAwesomeIcon icon={faTasks} />
            Challenges
          </Link>
          <Link
            href="/company/profile"
            className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-sm sm:text-base"
          >
            <FontAwesomeIcon icon={faUser} />
            Profile
          </Link>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-sm sm:text-base"
          >
            <FontAwesomeIcon icon={faSignOutAlt} />
            Logout
          </button>
        </div>

        {/* Mobile Menu */}
        {isMenuOpen && (
          <div className="absolute top-full left-0 w-full bg-[var(--accent)] shadow-md sm:hidden">
            <div className="flex flex-col items-start gap-4 p-4">
              <Link
                href="/company/dashboard"
                className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-base w-full"
                onClick={toggleMenu}
              >
                <FontAwesomeIcon icon={faHome} />
                Dashboard
              </Link>
              <Link
                href="/company/challenges"
                className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-base w-full"
                onClick={toggleMenu}
              >
                <FontAwesomeIcon icon={faTasks} />
                Challenges
              </Link>
              <Link
                href="/company/profile"
                className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-base w-full"
                onClick={toggleMenu}
              >
                <FontAwesomeIcon icon={faUser} />
                Profile
              </Link>
              <button
                onClick={() => {
                  handleLogout();
                  toggleMenu();
                }}
                className="flex items-center gap-2 hover:text-[var(--primary)] transition-colors text-base w-full"
              >
                <FontAwesomeIcon icon={faSignOutAlt} />
                Logout
              </button>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}