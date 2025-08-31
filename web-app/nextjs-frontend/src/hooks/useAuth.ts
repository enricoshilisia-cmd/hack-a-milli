"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { login, registerCompany, logout, getUser, isAuthenticated } from "../lib/auth";
import { useEffect } from "react";

interface User {
  id: string;
  email: string;
  role: string;
  first_name: string;
  last_name: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  registerCompany: (
    user: { email: string; password: string; first_name: string; last_name: string },
    company_name: string,
    company_domain: string,
    industry: string,
    website: string
  ) => Promise<{ message: string }>;
  logout: () => void;
  hydrateAuth: () => void;
  getAuthState: () => { user: User | null; token: string | null; isAuthenticated: boolean };
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      login: async (email: string, password: string) => {
        const { token, user } = await login(email, password);
        set({ user, token, isAuthenticated: true });
      },
      registerCompany: async (
        user: { email: string; password: string; first_name: string; last_name: string },
        company_name: string,
        company_domain: string,
        industry: string,
        website: string
      ) => {
        const response = await registerCompany(
          { ...user, role: "company_user" },
          company_name,
          company_domain,
          industry,
          website,
          "pending"
        );
        return { message: response.message };
      },
      logout: () => {
        logout();
        set({ user: null, token: null, isAuthenticated: false });
      },
      hydrateAuth: () => {
        const user = getUser();
        const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
        const authenticated = isAuthenticated();
        set({ user, token, isAuthenticated: authenticated });
      },
      getAuthState: () => {
        if (typeof window === "undefined") {
          return { user: null, token: null, isAuthenticated: false };
        }
        const user = getUser();
        const token = localStorage.getItem("token");
        const authenticated = isAuthenticated();
        return { user, token, isAuthenticated: authenticated };
      },
    }),
    {
      name: "auth-storage",
      storage: {
        getItem: (name) => {
          if (typeof window === "undefined") return null;
          const str = localStorage.getItem(name);
          return str ? JSON.parse(str) : null;
        },
        setItem: (name, value) => {
          if (typeof window !== "undefined") {
            localStorage.setItem(name, JSON.stringify(value));
          }
        },
        removeItem: (name) => {
          if (typeof window !== "undefined") {
            localStorage.removeItem(name);
          }
        },
      },
    }
  )
);

// Hydrate the store on the client side
export const useAuthHydration = () => {
  const hydrateAuth = useAuthStore((state) => state.hydrateAuth);
  useEffect(() => {
    hydrateAuth();
  }, [hydrateAuth]);
};