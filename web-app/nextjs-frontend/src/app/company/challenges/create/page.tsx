"use client";

import { useState, useEffect } from "react";
import { useAuthStore } from "@/hooks/useAuth";
import api from "@/lib/api";
import { useRouter } from "next/navigation";
import { ChallengeCategory } from "@/types/challenge";

interface FormData {
  title: string;
  description: string;
  challenge_type: string;
  difficulty: string;
  visibility: "public" | "company" | "group";
  start_date: string;
  end_date: string;
  max_submissions: number;
  is_collaborative: boolean;
  max_team_size: string;
  skill_tags: string;
  learning_outcomes: string;
  prerequisite_description: string;
  estimated_completion_time: string;
  max_score: number;
  is_published: boolean;
  categories: string[];
}

export default function CreateChallengePage() {
  const { user, isAuthenticated } = useAuthStore();
  const router = useRouter();
  const [formData, setFormData] = useState<FormData>({
    title: "",
    description: "",
    challenge_type: "",
    difficulty: "",
    visibility: "public",
    start_date: "",
    end_date: "",
    max_submissions: 1,
    is_collaborative: false,
    max_team_size: "",
    skill_tags: "",
    learning_outcomes: "",
    prerequisite_description: "",
    estimated_completion_time: "",
    max_score: 100,
    is_published: false,
    categories: [],
  });
  const [categories, setCategories] = useState<ChallengeCategory[]>([]);
  const [categoryQuery, setCategoryQuery] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>("");
  const [success, setSuccess] = useState<string>("");

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") {
      router.push("/auth/login");
      return;
    }

    const fetchCategories = async () => {
      try {
        const response = await api.get("/companies/categories/search/", {
          params: { q: categoryQuery },
        });
        setCategories(response.data.categories);
      } catch (err: unknown) {
        setError("Failed to load categories");
      }
    };

    if (categoryQuery.length >= 4) {
      fetchCategories();
    } else {
      setCategories([]);
    }
  }, [isAuthenticated, user, router, categoryQuery]);

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value, type } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? (e.target as HTMLInputElement).checked : value,
    }));
  };

  const handleCategoryToggle = (categoryName: string) => {
    const normalizedName = categoryName.trim();
    setFormData((prev) => {
      const updatedCategories = prev.categories.includes(normalizedName)
        ? prev.categories.filter((c) => c !== normalizedName)
        : [...prev.categories, normalizedName];
      return { ...prev, categories: updatedCategories };
    });
  };

  const handleAddCategory = () => {
    const normalizedName = categoryQuery.trim();
    if (normalizedName && !formData.categories.includes(normalizedName)) {
      handleCategoryToggle(normalizedName);
      setCategoryQuery("");
    }
  };

  const handleCategoryKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleAddCategory();
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");

    if (formData.categories.length === 0) {
      setError("At least one category is required.");
      setLoading(false);
      return;
    }

    try {
      const payload = {
        ...formData,
        categories: formData.categories.map((name) => ({ name: name.trim() })),
        start_date: formData.start_date ? `${formData.start_date}:00Z` : "",
        end_date: formData.end_date ? `${formData.end_date}:59Z` : "",
        max_submissions: parseInt(formData.max_submissions.toString(), 10),
        max_team_size: formData.max_team_size ? parseInt(formData.max_team_size, 10) : null,
        estimated_completion_time: formData.estimated_completion_time
          ? parseInt(formData.estimated_completion_time, 10)
          : null,
        max_score: parseFloat(formData.max_score.toString()),
      };

      // Validate numeric fields
      if (
        formData.estimated_completion_time &&
        isNaN(payload.estimated_completion_time as number)
      ) {
        setError("Estimated completion time must be a valid number.");
        setLoading(false);
        return;
      }
      if (formData.max_team_size && isNaN(payload.max_team_size as number)) {
        setError("Max team size must be a valid number.");
        setLoading(false);
        return;
      }

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const response = await api.post("/companies/company/challenges/create/", payload, {
        headers: { "Content-Type": "application/json" },
      });

      setSuccess("Challenge created successfully");
      setTimeout(() => router.push("/company/challenges"), 2000);
    } catch (err: unknown) {
      console.error("Error creating challenge:", err);
      let errorMessage: string;
      if (
        err instanceof Error &&
        "response" in err &&
        err.response &&
        typeof err.response === "object" &&
        "data" in err.response
      ) {
        errorMessage =
          typeof err.response.data === "string"
            ? err.response.data
            : typeof err.response.data === "object" && err.response.data
            ? JSON.stringify(err.response.data)
            : err.message || "Failed to create challenge";
      } else if (err instanceof Error) {
        errorMessage = err.message || "Failed to create challenge";
      } else {
        errorMessage = "Failed to create challenge";
      }
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--background)] p-8">
      <header className="mb-8">
        <h1 className="text-4xl font-bold text-[var(--foreground)]">Create New Challenge</h1>
        <p className="text-[var(--foreground)]/70 mt-2">Fill in the details to create a new challenge.</p>
      </header>
      <section className="bg-[var(--neutral)] p-6 rounded-xl shadow-md max-w-2xl mx-auto">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Title
            </label>
            <input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              required
            />
          </div>
          <div>
            <label htmlFor="description" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Description
            </label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              rows={4}
              required
            />
          </div>
          <div>
            <label htmlFor="challenge_type" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Challenge Type
            </label>
            <select
              id="challenge_type"
              name="challenge_type"
              value={formData.challenge_type}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              required
            >
              <option value="">Select Type</option>
              {[
                "coding",
                "design",
                "document",
                "data_analysis",
                "case_study",
                "presentation",
                "quiz",
                "simulation",
                "creative_writing",
                "project_management",
                "financial_analysis",
                "marketing_campaign",
                "sales_pitch",
                "hr_strategy",
                "research",
                "video_production",
                "consulting",
                "product_design",
                "other",
              ].map((type) => (
                <option key={type} value={type}>
                  {type.charAt(0).toUpperCase() + type.slice(1).replace("_", " ")}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="difficulty" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Difficulty
            </label>
            <select
              id="difficulty"
              name="difficulty"
              value={formData.difficulty}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              required
            >
              <option value="">Select Difficulty</option>
              {["beginner", "easy", "medium", "hard", "expert"].map((diff) => (
                <option key={diff} value={diff}>
                  {diff.charAt(0).toUpperCase() + diff.slice(1)}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="visibility" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Visibility
            </label>
            <select
              id="visibility"
              name="visibility"
              value={formData.visibility}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            >
              {["public", "company", "group"].map((vis) => (
                <option key={vis} value={vis}>
                  {vis.charAt(0).toUpperCase() + vis.slice(1).replace("_", " ")}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="categories" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Categories
            </label>
            <div className="flex items-center space-x-2">
              <input
                type="text"
                id="categories"
                value={categoryQuery}
                onChange={(e) => setCategoryQuery(e.target.value)}
                onKeyPress={handleCategoryKeyPress}
                placeholder="Type category name and press Enter to add"
                className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              />
              <button
                type="button"
                onClick={handleAddCategory}
                className="bg-[var(--primary)] text-white px-4 py-2 rounded-md hover:bg-[var(--primary)]/80"
              >
                Add
              </button>
            </div>
            {categories.length > 0 && (
              <div className="mt-2 max-h-40 overflow-y-auto bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md">
                {categories.map((cat) => (
                  <div
                    key={cat.id}
                    className="px-4 py-2 hover:bg-[var(--neutral)] cursor-pointer"
                    onClick={() => handleCategoryToggle(cat.name)}
                  >
                    <input
                      type="checkbox"
                      checked={formData.categories.includes(cat.name)}
                      onChange={() => handleCategoryToggle(cat.name)}
                      className="mr-2"
                    />
                    {cat.name} - {cat.description}
                  </div>
                ))}
              </div>
            )}
            <div className="mt-2">
              {formData.categories.length > 0 ? (
                <p>Selected: {formData.categories.join(", ")}</p>
              ) : (
                <p className="text-[var(--foreground)]/80">No categories selected</p>
              )}
            </div>
          </div>
          <div>
            <label htmlFor="start_date" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Start Date
            </label>
            <input
              type="datetime-local"
              id="start_date"
              name="start_date"
              value={formData.start_date}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            />
          </div>
          <div>
            <label htmlFor="end_date" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              End Date
            </label>
            <input
              type="datetime-local"
              id="end_date"
              name="end_date"
              value={formData.end_date}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            />
          </div>
          <div>
            <label htmlFor="max_submissions" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Max Submissions
            </label>
            <input
              type="number"
              id="max_submissions"
              name="max_submissions"
              value={formData.max_submissions}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              min="1"
            />
          </div>
          <div>
            <label htmlFor="is_collaborative" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Collaborative
            </label>
            <input
              type="checkbox"
              id="is_collaborative"
              name="is_collaborative"
              checked={formData.is_collaborative}
              onChange={handleInputChange}
              className="h-5 w-5 text-[var(--primary)]"
            />
          </div>
          <div>
            <label htmlFor="max_team_size" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Max Team Size
            </label>
            <input
              type="number"
              id="max_team_size"
              name="max_team_size"
              value={formData.max_team_size}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              min="1"
            />
          </div>
          <div>
            <label htmlFor="skill_tags" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Skill Tags
            </label>
            <input
              type="text"
              id="skill_tags"
              name="skill_tags"
              value={formData.skill_tags}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              placeholder="e.g., Python, Django"
            />
          </div>
          <div>
            <label htmlFor="learning_outcomes" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Learning Outcomes
            </label>
            <textarea
              id="learning_outcomes"
              name="learning_outcomes"
              value={formData.learning_outcomes}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              rows={4}
            />
          </div>
          <div>
            <label htmlFor="prerequisite_description" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Prerequisite Description
            </label>
            <textarea
              id="prerequisite_description"
              name="prerequisite_description"
              value={formData.prerequisite_description}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              rows={4}
            />
          </div>
          <div>
            <label htmlFor="estimated_completion_time" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Estimated Completion Time (minutes)
            </label>
            <input
              type="number"
              id="estimated_completion_time"
              name="estimated_completion_time"
              value={formData.estimated_completion_time}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              min="1"
            />
          </div>
          <div>
            <label htmlFor="max_score" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Max Score
            </label>
            <input
              type="number"
              id="max_score"
              name="max_score"
              value={formData.max_score}
              onChange={handleInputChange}
              className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--neutral)]/20 rounded-md text-[var(--foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
              min="1"
            />
          </div>
          <div>
            <label htmlFor="is_published" className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Publish Immediately
            </label>
            <input
              type="checkbox"
              id="is_published"
              name="is_published"
              checked={formData.is_published}
              onChange={handleInputChange}
              className="h-5 w-5 text-[var(--primary)]"
            />
          </div>
          {error && <p className="text-red-500">{error}</p>}
          {success && <p className="text-green-500">{success}</p>}
          <button
            type="submit"
            disabled={loading}
            className="bg-[var(--primary)] text-white px-6 py-2 rounded-md hover:bg-[var(--primary)]/80 disabled:opacity-50"
          >
            {loading ? "Creating..." : "Create Challenge"}
          </button>
        </form>
      </section>
    </div>
  );
}