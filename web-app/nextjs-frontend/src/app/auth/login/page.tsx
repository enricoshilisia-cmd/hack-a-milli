"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import AuthForm from "@/components/AuthForm";
import { useAuthStore } from "@/hooks/useAuth";
import WavyBackground from "@/components/WavyBackground";

// Define interfaces (move to shared types file if reused)
interface LoginData {
  email: string;
  password: string;
}

interface RegisterData {
  user: {
    email: string;
    password: string;
    first_name: string;
    last_name: string;
  };
  company_name: string;
  company_domain: string;
  industry: string;
  website: string;
}

export default function LoginPage() {
  const router = useRouter();
  const { login, isAuthenticated, user } = useAuthStore();

  useEffect(() => {
    if (isAuthenticated && user?.role === "company_user") {
      router.push("/company/dashboard");
    }
  }, [isAuthenticated, user, router]);

  const handleLogin = async (data: LoginData | RegisterData) => {
    if ("email" in data && "password" in data) {
      await login(data.email, data.password);
      return { message: "Login successful" };
    }
    throw new Error("Invalid data for login");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--background)] py-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      <WavyBackground opacity={0.1} />
      <div className="relative z-10 w-full max-w-lg">
        <AuthForm onSubmit={handleLogin} type="login" />
      </div>
    </div>
  );
}