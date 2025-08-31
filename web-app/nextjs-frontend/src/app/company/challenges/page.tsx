"use client";

import { useState, useEffect } from "react";
import { useAuthStore } from "@/hooks/useAuth";
import api from "@/lib/api";
import Link from "next/link";
import ChallengeRow from "@/components/ChallengeRow";
import { CategorizedChallenges, Challenge } from "@/types/challenge";

export default function CompanyChallengesPage() {
  const { user, isAuthenticated } = useAuthStore();
  const [categorizedChallenges, setCategorizedChallenges] = useState<CategorizedChallenges>({});
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>("");

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") return;

    const fetchChallenges = async () => {
      setLoading(true);
      try {
        const response = await api.get<CategorizedChallenges>("/companies/company/challenges/", {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        setCategorizedChallenges(response.data);
      } catch (err: unknown) {
        const errorMessage = err instanceof Error ? err.message || "Failed to load challenges" : "Failed to load challenges";
        setError(errorMessage);
      } finally {
        setLoading(false);
      }
    };

    fetchChallenges();
  }, [isAuthenticated, user]);

  if (loading) {
    return (
      <div className="flex items-center justify-center px-4 py-8 bg-[var(--background)]">
        <p className="text-lg sm:text-xl text-[var(--foreground)] text-center">Loading challenges...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center px-4 py-8 bg-[var(--background)]">
        <p className="text-lg sm:text-xl text-red-500 text-center">{error}</p>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8 pt-6 pb-4 bg-[var(--background)]">
      <header className="mb-4 sm:mb-6 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-[var(--foreground)]">Company Challenges</h1>
          <p className="text-sm sm:text-base text-[var(--foreground)]/70 mt-2">Manage your company’s challenges below.</p>
        </div>
        <Link
          href="/company/challenges/create"
          className="bg-[var(--primary)] text-white px-4 sm:px-6 py-2 rounded-md hover:bg-[var(--primary)]/80 text-sm sm:text-base text-center"
        >
          Create New Challenge
        </Link>
      </header>

      {Object.keys(categorizedChallenges).length > 0 ? (
        Object.entries(categorizedChallenges).map(([category, challenges]) => (
          <section key={category} className="mb-4 sm:mb-6">
            <h2 className="text-lg sm:text-xl lg:text-2xl font-semibold text-[var(--foreground)] mb-3 sm:mb-4">
              {category.charAt(0).toUpperCase() + category.slice(1)}
            </h2>
            <div className="sm:hidden space-y-4">
              {challenges.map((challenge: Challenge) => (
                <div
                  key={challenge.id}
                  className="bg-[var(--neutral)] p-3 rounded-xl shadow-md border border-[var(--neutral)]/20 hover:border-[var(--primary)] hover:shadow-lg transition-all duration-300"
                >
                  <div className="flex justify-between items-start">
                    <h3 className="text-sm font-medium text-[var(--foreground)] truncate">{challenge.title}</h3>
                    {challenge.submission_count > 0 && (
                      <Link
                        href={`/company/challenges/${challenge.id}/submissions`}
                        className="bg-[var(--primary)] text-white text-xs font-medium px-2 py-1 rounded-full hover:bg-[var(--primary)]/80"
                      >
                        {challenge.submission_count} {challenge.submission_count === 1 ? "Submission" : "Submissions"}
                      </Link>
                    )}
                  </div>
                  <p className="text-xs text-[var(--foreground)]/80">
                    Type: {challenge.challenge_type.charAt(0).toUpperCase() + challenge.challenge_type.slice(1)}
                  </p>
                  <p className="text-xs text-[var(--foreground)]/80">
                    Difficulty: {challenge.difficulty.charAt(0).toUpperCase() + challenge.difficulty.slice(1)}
                  </p>
                  <p className="text-xs font-medium">
                    <span className={challenge.is_published ? "text-green-500" : "text-yellow-500"}>
                      {challenge.is_published ? "Published" : "Draft"}
                    </span>
                  </p>
                  <div className="flex gap-2 mt-2">
                    <Link
                      href={`/company/challenges/${challenge.id}`}
                      className="text-[var(--primary)] text-xs hover:underline inline-block"
                    >
                      View Details
                    </Link>
                    {challenge.submission_count > 0 && (
                      <Link
                        href={`/company/challenges/${challenge.id}/submissions`}
                        className="text-[var(--primary)] text-xs hover:underline inline-block"
                      >
                        Review Submissions
                      </Link>
                    )}
                  </div>
                </div>
              ))}
            </div>
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full bg-[var(--neutral)] rounded-xl shadow-md table-fixed">
                <thead>
                  <tr className="text-left text-[var(--foreground)]/80 border-b border-[var(--neutral)]/20">
                    <th className="px-2 sm:px-4 py-2 w-[40%] sm:w-[35%]">Title</th>
                    <th className="px-2 sm:px-4 py-2 w-[20%] sm:w-[15%]">Type</th>
                    <th className="px-2 sm:px-4 py-2 w-[20%] sm:w-[15%]">Difficulty</th>
                    <th className="px-2 sm:px-4 py-2 w-[10%] sm:w-[15%]">Status</th>
                    <th className="px-2 sm:px-4 py-2 w-[10%] sm:w-[20%]">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {challenges.map((challenge: Challenge) => (
                    <ChallengeRow key={challenge.id} challenge={challenge} />
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        ))
      ) : (
        <p className="text-sm sm:text-base text-[var(--foreground)]/80">No challenges found. Create a new challenge to get started.</p>
      )}
    </div>
  );
}