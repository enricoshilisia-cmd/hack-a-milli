"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import AuthForm from "../../../components/AuthForm";
import { useAuthStore } from "../../../hooks/useAuth";
import WavyBackground from "../../../components/WavyBackground";

// Import the interfaces from AuthForm to ensure consistency
import { LoginData, RegisterData } from "../../../components/AuthForm";

export default function RegisterPage() {
  const router = useRouter();
  const { registerCompany, isAuthenticated, user } = useAuthStore();

  useEffect(() => {
    if (isAuthenticated && user?.role === "company_user") {
      router.push("/company/dashboard");
    }
  }, [isAuthenticated, user, router]);

  const handleRegister = async (data: LoginData | RegisterData) => {
    // Ensure data is RegisterData since this is the register page
    if ("user" in data) {
      const response = await registerCompany(
        data.user,
        data.company_name,
        data.company_domain,
        data.industry,
        data.website
      );
      console.log("RegisterPage response:", response); // Debug log
      return response; // Return { message } for AuthForm to display
    }
    // Handle unexpected LoginData case (though it won't occur in register flow)
    throw new Error("Invalid data format for registration");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--background)] py-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Wavy Animation Background */}
      <WavyBackground opacity={0.1} /> {/* Reduced opacity for subtlety */}
      {/* AuthForm centered over the wave */}
      <div className="relative z-10 w-full max-w-lg">
        <AuthForm onSubmit={handleRegister} type="register" />
      </div>
    </div>
  );
}