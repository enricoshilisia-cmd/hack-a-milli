import { AxiosError } from "axios";
import api from "./api";

interface User {
  id: string;
  email: string;
  role: string;
  first_name: string;
  last_name: string;
}

interface LoginResponse {
  token: string;
  user: User;
}

interface RegisterResponse {
  message: string;
  token?: string;
  user?: User;
}

interface CompanyProfile {
  company_name: string;
  industry: string;
  website: string;
  verification_status: string;
}

export const login = async (email: string, password: string): Promise<LoginResponse> => {
  try {
    const response = await api.post<LoginResponse>("/users/login/", { email, password });
    const { token, user } = response.data;
    if (typeof window !== "undefined") {
      localStorage.setItem("token", token);
      localStorage.setItem("user", JSON.stringify(user));
    }
    return response.data;
  } catch (error: unknown) {
    const err = error as AxiosError<{ error?: string }>;
    throw new Error(err.response?.data?.error || "Login failed");
  }
};

export const registerCompany = async (
  user: { email: string; password: string; role: string; first_name: string; last_name: string },
  company_name: string,
  company_domain: string,
  industry: string,
  website: string,
  verification_status: string
): Promise<RegisterResponse> => {
  try {
    const response = await api.post<RegisterResponse>("/users/register/company/", {
      user: { ...user, role: "company_user" },
      company_name,
      company_domain,
      industry,
      website,
      verification_status,
    });
    if (response.data.token && response.data.user && typeof window !== "undefined") {
      localStorage.setItem("token", response.data.token);
      localStorage.setItem("user", JSON.stringify(response.data.user));
    }
    return response.data;
  } catch (error: unknown) {
    const err = error as AxiosError<{ error?: string }>;
    if (err.response?.status === 400) {
      throw new Error(err.response?.data?.error || JSON.stringify(err.response?.data) || "Registration failed");
    }
    throw err;
  }
};

export const getCompanyProfile = async (): Promise<CompanyProfile> => {
  try {
    const response = await api.get<CompanyProfile>("/users/profile/", {
      headers: { Authorization: `Token ${typeof window !== "undefined" ? localStorage.getItem("token") : ""}` },
    });
    return response.data;
  } catch (error: unknown) {
    const err = error as AxiosError<{ error?: string }>;
    throw new Error(err.response?.data?.error || "Failed to fetch company profile");
  }
};

export const logout = () => {
  if (typeof window !== "undefined") {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
  }
};

export const getUser = (): User | null => {
  if (typeof window === "undefined") return null;
  const user = localStorage.getItem("user");
  return user ? JSON.parse(user) : null;
};

export const isAuthenticated = (): boolean => {
  if (typeof window === "undefined") return false;
  return !!localStorage.getItem("token");
};