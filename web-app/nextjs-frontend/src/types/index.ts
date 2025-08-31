// src/types/index.ts
export interface LoginData {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  role: string;
  company_name?: string; // Optional, for company registration
  company_domain?: string;
  industry?: string;
  website?: string;
  verification_status?: string;
}

export interface CompanyProfile {
  name: string;
  industry: string;
  website: string;
  logo: string | null; // Logo can be a URL or null
  domain: string;
  verified: boolean;
}