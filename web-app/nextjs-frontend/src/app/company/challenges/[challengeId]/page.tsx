"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuthStore } from "@/hooks/useAuth";
import api from "@/lib/api";
import Link from "next/link";
import { Submission } from "@/types/submission";

export default function ChallengeSubmissionsPage() {
  const { challengeId } = useParams<{ challengeId: string }>();
  const { user, isAuthenticated } = useAuthStore();
  const router = useRouter();
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>("");

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") {
      router.push("/auth/login");
      return;
    }

    const fetchSubmissions = async () => {
      setLoading(true);
      try {
        const response = await api.get<Submission[]>(`/companies/company/challenges/${challengeId}/submissions/`, {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        setSubmissions(response.data);
      } catch (err: unknown) {
        // Check if err is an Error instance
        if (err instanceof Error) {
          setError(err.message || "Failed to load submissions");
        } else {
          setError("Failed to load submissions");
        }
      } finally {
        setLoading(false);
      }
    };

    fetchSubmissions();
  }, [isAuthenticated, user, challengeId, router]);

  if (loading) {
    return (
      <div className="flex items-center justify-center px-4 py-8 bg-[var(--background)]">
        <p className="text-lg sm:text-xl text-[var(--foreground)] text-center">Loading submissions...</p>
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
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-[var(--foreground)]">Challenge Submissions</h1>
          <p className="text-sm sm:text-base text-[var(--foreground)]/70 mt-2">Review submissions for this challenge.</p>
        </div>
        <Link
          href={`/company/challenges/${challengeId}`}
          className="bg-[var(--primary)] text-white px-4 sm:px-6 py-2 rounded-md hover:bg-[var(--primary)]/80 text-sm sm:text-base text-center"
        >
          Back to Challenge
        </Link>
      </header>

      {submissions.length > 0 ? (
        <>
          <div className="sm:hidden space-y-4">
            {submissions.map((submission) => (
              <div
                key={submission.id}
                className="bg-[var(--neutral)] p-3 rounded-xl shadow-md border border-[var(--neutral)]/20 hover:border-[var(--primary)] hover:shadow-lg transition-all duration-300"
              >
                <p className="text-sm font-medium text-[var(--foreground)]">{submission.user.email}</p>
                <p className="text-xs text-[var(--foreground)]/80">
                  Submitted: {new Date(submission.submitted_at).toLocaleDateString()}
                </p>
                <p className="text-xs text-[var(--foreground)]/80">
                  Status: {submission.status.charAt(0).toUpperCase() + submission.status.slice(1)}
                </p>
                <p className="text-xs text-[var(--foreground)]/80">Score: {submission.reviews?.[0]?.score ?? "N/A"}</p>
                <Link
                  href={`/company/challenges/${challengeId}/submissions/${submission.id}`}
                  className="text-[var(--primary)] text-xs hover:underline mt-2 inline-block"
                >
                  Review Submission
                </Link>
              </div>
            ))}
          </div>
          <div className="hidden sm:block overflow-x-auto">
            <table className="w-full bg-[var(--neutral)] rounded-xl shadow-md table-fixed">
              <thead>
                <tr className="text-left text-[var(--foreground)]/80 border-b border-[var(--neutral)]/20">
                  <th className="px-2 sm:px-4 py-2 w-[30%]">Student</th>
                  <th className="px-2 sm:px-4 py-2 w-[20%]">Submitted At</th>
                  <th className="px-2 sm:px-4 py-2 w-[20%]">Status</th>
                  <th className="px-2 sm:px-4 py-2 w-[15%]">Score</th>
                  <th className="px-2 sm:px-4 py-2 w-[15%]">Actions</th>
                </tr>
              </thead>
              <tbody>
                {submissions.map((submission) => (
                  <tr key={submission.id} className="border-b border-[var(--neutral)]/20 last:border-none">
                    <td className="px-2 sm:px-4 py-2 text-[var(--foreground)]">{submission.user.email}</td>
                    <td className="px-2 sm:px-4 py-2 text-[var(--foreground)]/80">
                      {new Date(submission.submitted_at).toLocaleDateString()}
                    </td>
                    <td className="px-2 sm:px-4 py-2">
                      <span
                        className={`font-medium ${
                          submission.status === "graded"
                            ? "text-green-500"
                            : submission.status === "rejected"
                            ? "text-red-500"
                            : "text-yellow-500"
                        }`}
                      >
                        {submission.status.charAt(0).toUpperCase() + submission.status.slice(1)}
                      </span>
                    </td>
                    <td className="px-2 sm:px-4 py-2 text-[var(--foreground)]">
                      {submission.reviews?.[0]?.score ?? "N/A"}
                    </td>
                    <td className="px-2 px-4 py-2">
                      <Link
                        href={`/company/challenges/${challengeId}/submissions/${submission.id}`}
                        className="text-[var(--primary)] hover:underline"
                      >
                        Review
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <p className="text-sm sm:text-base text-[var(--foreground)]/80">No submissions found for this challenge.</p>
      )}
    </div>
  );
}