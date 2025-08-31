"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import CompNavbar from "@/components/CompNavbar";
import { useAuthStore, useAuthHydration } from "@/hooks/useAuth";
import WavyBackground from "@/components/WavyBackground";

export default function CompanyLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  useAuthHydration(); // Hydrate auth store on client

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") {
      router.push("/auth/login");
    }
  }, [isAuthenticated, user, router]);

  return (
    <div className="min-h-screen bg-[var(--background)] relative overflow-hidden">
      {/* Wavy Animation Background */}
      <WavyBackground opacity={0.1} /> {/* Same subtle opacity as LoginPage */}
      {/* Fixed Navbar */}
      <CompNavbar />
      {/* Main content with padding to account for fixed navbar */}
      <main className="container mx-auto p-4 pt-20 relative z-10">{children}</main>
    </div>
  );
}