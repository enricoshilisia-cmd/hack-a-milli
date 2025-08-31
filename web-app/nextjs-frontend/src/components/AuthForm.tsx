"use client";

import { useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEnvelope, faLock, faUser, faBuilding, faCheckCircle, faExclamationCircle } from "@fortawesome/free-solid-svg-icons";
import Link from "next/link";
import { motion } from "framer-motion";

// Define and export interfaces for form data
export interface LoginData {
  email: string;
  password: string;
}

export interface RegisterData {
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

interface AuthFormProps {
  onSubmit: (data: LoginData | RegisterData) => Promise<{ message?: string }>;
  type: "login" | "register";
}

export default function AuthForm({ onSubmit, type }: AuthFormProps) {
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  const [firstName, setFirstName] = useState<string>("");
  const [lastName, setLastName] = useState<string>("");
  const [companyName, setCompanyName] = useState<string>("");
  const [companyDomain, setCompanyDomain] = useState<string>("");
  const [industry, setIndustry] = useState<string>("");
  const [website, setWebsite] = useState<string>("");
  const [error, setError] = useState<string>("");
  const [success, setSuccess] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    setLoading(true);
    try {
      if (type === "login") {
        await onSubmit({ email, password });
      } else {
        const response = await onSubmit({
          user: { email, password, first_name: firstName, last_name: lastName },
          company_name: companyName,
          company_domain: companyDomain,
          industry,
          website,
        });
        setSuccess(response.message || "Registration successful, pending domain verification");
      }
    } catch (err: unknown) {
      // Check if err is an Error instance
      if (err instanceof Error) {
        setError(err.message || "An error occurred");
      } else {
        setError("An unexpected error occurred");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="max-w-lg w-full mx-auto bg-[var(--background)] p-6 sm:p-8 rounded-xl shadow-xl border border-[var(--neutral)]/50"
    >
      <h2 className="text-3xl font-bold text-[var(--foreground)] mb-8 text-center">
        {type === "login" ? "Sign In" : "Register as Company"}
      </h2>
      {error && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="mb-6 p-4 bg-red-100 dark:bg-red-900/30 border border-red-300 dark:border-red-700 rounded-lg flex items-center gap-3"
        >
          <FontAwesomeIcon icon={faExclamationCircle} className="text-red-500 dark:text-red-400" />
          <p className="text-red-600 dark:text-red-300 font-medium">{error}</p>
        </motion.div>
      )}
      {success && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="mb-6 p-4 bg-green-100 dark:bg-green-900/30 border border-green-300 dark:border-green-700 rounded-lg"
        >
          <div className="flex items-center gap-3 mb-3">
            <FontAwesomeIcon icon={faCheckCircle} className="text-green-500 dark:text-green-400" />
            <p className="text-green-600 dark:text-green-300 font-medium">{success}</p>
          </div>
          <p className="text-[var(--foreground)]/80 text-sm">
            Your company domain is under verification. You will be notified once approved. For assistance, contact{" "}
            <a href="mailto:support@skillproof.co.ke" className="text-[var(--primary)] underline hover:text-[var(--secondary)]">
              support@skillproof.co.ke
            </a>.
          </p>
          <p className="text-[var(--foreground)]/80 text-sm mt-3">
            Return to{" "}
            <Link href="/auth/login" className="text-[var(--primary)] underline hover:text-[var(--secondary)]">
              Login
            </Link>{" "}
            to try logging in after verification.
          </p>
        </motion.div>
      )}
      {!success && (
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
              <FontAwesomeIcon icon={faEnvelope} className="text-[var(--primary)] w-4" />
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
              placeholder="Enter your email"
              required
            />
          </div>
          <div>
            <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
              <FontAwesomeIcon icon={faLock} className="text-[var(--primary)] w-4" />
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
              placeholder="Enter your password"
              required
            />
          </div>
          {type === "register" && (
            <>
              <div>
                <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
                  <FontAwesomeIcon icon={faUser} className="text-[var(--primary)] w-4" />
                  First Name
                </label>
                <input
                  type="text"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
                  placeholder="Enter your first name"
                  required
                />
              </div>
              <div>
                <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
                  <FontAwesomeIcon icon={faUser} className="text-[var(--primary)] w-4" />
                  Last Name
                </label>
                <input
                  type="text"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
                  placeholder="Enter your last name"
                  required
                />
              </div>
              <div>
                <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
                  <FontAwesomeIcon icon={faBuilding} className="text-[var(--primary)] w-4" />
                  Company Name
                </label>
                <input
                  type="text"
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
                  placeholder="Enter company name"
                  required
                />
              </div>
              <div>
                <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
                  <FontAwesomeIcon icon={faBuilding} className="text-[var(--primary)] w-4" />
                  Company Domain
                </label>
                <input
                  type="text"
                  value={companyDomain}
                  onChange={(e) => setCompanyDomain(e.target.value)}
                  className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
                  placeholder="Enter company domain (e.g., example.com)"
                  required
                />
              </div>
              <div>
                <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
                  <FontAwesomeIcon icon={faBuilding} className="text-[var(--primary)] w-4" />
                  Industry
                </label>
                <input
                  type="text"
                  value={industry}
                  onChange={(e) => setIndustry(e.target.value)}
                  className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
                  placeholder="Enter industry (e.g., Technology)"
                  required
                />
              </div>
              <div>
                <label className="flex items-center gap-3 text-[var(--foreground)] font-semibold mb-2 text-sm">
                  <FontAwesomeIcon icon={faBuilding} className="text-[var(--primary)] w-4" />
                  Website
                </label>
                <input
                  type="url"
                  value={website}
                  onChange={(e) => setWebsite(e.target.value)}
                  className="w-full p-3 rounded-lg border border-[var(--neutral)]/50 bg-[var(--neutral)]/10 text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-[var(--primary)] transition-all placeholder:text-[var(--foreground)]/50"
                  placeholder="Enter website (e.g., https://example.com)"
                  required
                />
              </div>
            </>
          )}
          <button
            type="submit"
            disabled={loading || !!success}
            className="w-full bg-[var(--accent)] text-[var(--background)] py-3 px-4 rounded-full font-semibold text-lg hover:bg-[var(--secondary)] transition-colors duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? "Loading..." : type === "login" ? "Sign In" : "Register"}
          </button>
        </form>
      )}
    </motion.div>
  );
}