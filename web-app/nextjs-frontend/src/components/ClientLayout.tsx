"use client";

import { usePathname } from "next/navigation";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { useAuthStore, useAuthHydration } from "@/hooks/useAuth";

export default function ClientLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { isAuthenticated, user } = useAuthStore();
  useAuthHydration(); // Hydrate auth store on client

  // Exclude Navbar and Footer for /company/* routes or if user is a company_user
  const excludeNavbarAndFooter = pathname.startsWith("/company") || (isAuthenticated && user?.role === "company_user");

  return (
    <>
      {!excludeNavbarAndFooter && <Navbar />}
      <main className="flex-1">{children}</main>
      {!excludeNavbarAndFooter && <Footer />}
    </>
  );
}