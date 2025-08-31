"use client";

import { useState, useEffect } from "react";
import { useAuthStore } from "@/hooks/useAuth";
import api from "@/lib/api";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { CompanyProfile } from "@/types"; // Fixed import path

export default function CompanyProfilePage() {
  const { user, isAuthenticated } = useAuthStore();
  const router = useRouter();
  const [profile, setProfile] = useState<CompanyProfile | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    industry: "",
    website: "",
  });
  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") {
      router.push("/auth/login");
      return;
    }

    const fetchProfile = async () => {
      setLoading(true);
      try {
        const response = await api.get("/companies/company/profile/", {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        const data: CompanyProfile = response.data;
        setProfile(data);
        setFormData({
          name: data.name || "",
          industry: data.industry || "",
          website: data.website || "",
        });
        setLogoPreview(data.logo || null);
      } catch (err: unknown) {
        setError(err instanceof Error ? err.message : "Failed to load profile");
      } finally {
        setLoading(false);
      }
    };

    fetchProfile();
  }, [isAuthenticated, user, router]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setLogoFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setLogoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setUpdating(true);
    setError("");
    setSuccess("");

    try {
      const data = new FormData();
      data.append("name", formData.name);
      data.append("industry", formData.industry);
      data.append("website", formData.website);
      if (logoFile) {
        data.append("logo", logoFile);
      }

      await api.put("/companies/company/profile/", data, {
        headers: {
          Authorization: `Token ${localStorage.getItem("token")}`,
          "Content-Type": "multipart/form-data",
        },
      });

      setSuccess("Profile updated successfully");
      router.push("/company/dashboard");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to update profile");
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-[var(--foreground)]">Loading profile...</p>
      </div>
    );
  }

  if (error && !profile) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-red-500">Error: {error}</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-8">
      <header className="mb-8">
        <h1 className="text-4xl font-bold text-[var(--foreground)]">Company Profile</h1>
        <p className="text-[var(--foreground)]/70 mt-2">Manage your company details below.</p>
      </header>
      <section className="bg-[var(--neutral)] p-6 rounded-xl shadow-md max-w-2xl mx-auto">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">Company Logo</label>
            {logoPreview ? (
              <div className="relative w-32 h-32 mb-4">
                <Image
                  src={logoPreview}
                  alt="Company Logo"
                  fill
                  className="object-contain rounded-md"
                  onError={() => setLogoPreview(null)}
                />
              </div>
            ) : (
              <p className="text-[var(--foreground)]/80 mb-4">No logo uploaded</p>
            )}
            <input
              type="file"
              accept="image/*"
              onChange={handleLogoChange}
              className="block w-full text-sm text-[var(--foreground)] file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-[var(--primary)] file:text-white hover:file:bg-[var(--primary)]/80"
            />
          </div>
          <div>
            <label htmlFor="name" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Company Name
            </label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            />
          </div>
          <div>
            <label htmlFor="industry" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Industry
            </label>
            <input
              type="text"
              id="industry"
              name="industry"
              value={formData.industry}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            />
          </div>
          <div>
            <label htmlFor="website" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Website
            </label>
            <input
              type="url"
              id="website"
              name="website"
              value={formData.website}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">Domain</label>
            <p className="text-[var(--foreground)]/80">{profile?.domain || "N/A"}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">Verified</label>
            <p className="text-[var(--foreground)]/80">{profile?.verified ? "Yes" : "No"}</p>
          </div>
          {error && <p className="text-red-500">{error}</p>}
          {success && <p className="text-green-500">{success}</p>}
          <button
            type="submit"
            disabled={updating}
            className="bg-[var(--primary)] text-white px-6 py-2 rounded-md hover:bg-[var(--primary)]/80 disabled:opacity-50"
          >
            {updating ? "Updating..." : "Update Profile"}
          </button>
        </form>
      </section>
    </div>
  );
}