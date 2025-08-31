"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuthStore } from "@/hooks/useAuth";
import api from "@/lib/api";
import Link from "next/link";
import { Submission } from "@/types/submission";

export default function SubmissionReviewPage() {
  const { challengeId, submissionId } = useParams<{ challengeId: string; submissionId: string }>();
  const { user, isAuthenticated } = useAuthStore();
  const router = useRouter();
  const [submission, setSubmission] = useState<Submission | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>("");
  const [score, setScore] = useState<string>("");
  const [comments, setComments] = useState<string>("");
  const [reviewError, setReviewError] = useState<string>("");
  const [reviewSuccess, setReviewSuccess] = useState<{ score: number; comments: string } | null>(null);

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") {
      router.push("/auth/login");
      return;
    }

    const fetchSubmission = async () => {
      setLoading(true);
      try {
        const response = await api.get<Submission[]>(`/companies/company/challenges/${challengeId}/submissions/`, {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        const submissionData = response.data.find((sub) => sub.id === parseInt(submissionId));
        if (!submissionData) {
          throw new Error("Submission not found");
        }
        // Ensure reviews is an array
        submissionData.reviews = submissionData.reviews || [];
        setSubmission(submissionData);
      } catch (err: unknown) {
        // Check if err is an Error instance
        if (err instanceof Error) {
          setError(err.message || "Failed to load submission");
        } else {
          setError("Failed to load submission");
        }
      } finally {
        setLoading(false);
      }
    };

    fetchSubmission();
  }, [isAuthenticated, user, challengeId, submissionId, router]);

  const handleReviewSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setReviewError("");
    setReviewSuccess(null);

    // Validate score locally
    const scoreNum = parseFloat(score);
    if (isNaN(scoreNum) || scoreNum < 0 || (submission && scoreNum > submission.challenge.max_score)) {
      setReviewError(`Score must be a number between 0 and ${submission?.challenge.max_score || "unknown"}`);
      return;
    }

    try {
      await api.post(
        `/companies/company/submissions/${submissionId}/review/`,
        { score: scoreNum, comments },
        { headers: { Authorization: `Token ${localStorage.getItem("token")}` } }
      );
      setReviewSuccess({ score: scoreNum, comments });
      setScore("");
      setComments("");
      // Refresh submission data to update status and reviews
      const updatedResponse = await api.get<Submission[]>(`/companies/company/challenges/${challengeId}/submissions/`, {
        headers: { Authorization: `Token ${localStorage.getItem("token")}` },
      });
      const updatedSubmission = updatedResponse.data.find((sub) => sub.id === parseInt(submissionId));
      if (updatedSubmission) {
        updatedSubmission.reviews = updatedSubmission.reviews || [];
        setSubmission(updatedSubmission);
      }
    } catch (err: unknown) {
      // Check if err is an Error instance
      const errorMessage = err instanceof Error ? err.message || "Failed to submit review" : "Failed to submit review";
      setReviewError(errorMessage);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center px-4 py-8 bg-[var(--background)]">
        <p className="text-lg sm:text-xl text-[var(--foreground)] text-center">Loading submission...</p>
      </div>
    );
  }

  if (error || !submission) {
    return (
      <div className="flex items-center justify-center px-4 py-8 bg-[var(--background)]">
        <p className="text-lg sm:text-xl text-red-500 text-center">{error || "Submission not found"}</p>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8 pt-6 pb-4 bg-[var(--background)]">
      <header className="mb-4 sm:mb-6 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-[var(--foreground)]">Review Submission</h1>
          <p className="text-sm sm:text-base text-[var(--foreground)]/70 mt-2">
            Review the submission for {submission.challenge.title}
          </p>
        </div>
        <Link
          href={`/company/challenges/${challengeId}/submissions`}
          className="bg-[var(--primary)] text-white px-4 sm:px-6 py-2 rounded-md hover:bg-[var(--primary)]/80 text-sm sm:text-base text-center"
        >
          Back to Submissions
        </Link>
      </header>

      {reviewSuccess && (
        <div className="mb-6 bg-green-100 border-l-4 border-green-500 p-4 rounded-md">
          <p className="text-green-700 font-medium">Review Submitted Successfully!</p>
          <p className="text-sm text-green-600">
            Score: {reviewSuccess.score} | Comments: {reviewSuccess.comments || "None"}
          </p>
          <button
            onClick={() => setReviewSuccess(null)}
            className="mt-2 text-sm text-green-700 hover:underline"
          >
            Dismiss
          </button>
        </div>
      )}

      <div className="bg-[var(--neutral)] p-4 sm:p-6 rounded-xl shadow-md border border-[var(--neutral)]/20">
        <h2 className="text-lg sm:text-xl font-semibold text-[var(--foreground)] mb-4">Submission Details</h2>
        <div className="space-y-3">
          <p className="text-sm sm:text-base text-[var(--foreground)]">
            <span className="font-medium">Student:</span> {submission.user.email}
          </p>
          <p className="text-sm sm:text-base text-[var(--foreground)]">
            <span className="font-medium">Challenge:</span> {submission.challenge.title}
          </p>
          <p className="text-sm sm:text-base text-[var(--foreground)]">
            <span className="font-medium">Submitted At:</span>{" "}
            {new Date(submission.submitted_at).toLocaleDateString()}
          </p>
          <p className="text-sm sm:text-base text-[var(--foreground)]">
            <span className="font-medium">Status:</span>{" "}
            <span
              className={`${
                submission.status === "graded"
                  ? "text-green-500"
                  : submission.status === "rejected"
                  ? "text-red-500"
                  : "text-yellow-500"
              } font-semibold`}
            >
              {submission.status.charAt(0).toUpperCase() + submission.status.slice(1)}
            </span>
          </p>
          <p className="text-sm sm:text-base text-[var(--foreground)]">
            <span className="font-medium">Repository Link:</span>{" "}
            <a
              href={submission.repo_link}
              target="_blank"
              rel="noopener noreferrer"
              className="text-[var(--primary)] hover:underline"
            >
              {submission.repo_link}
            </a>
          </p>
          {submission.files && submission.files.length > 0 && (
            <div>
              <p className="text-sm sm:text-base text-[var(--foreground)] font-medium">Files:</p>
              <ul className="list-disc list-inside text-sm sm:text-base text-[var(--foreground)]">
                {submission.files.map((file) => (
                  <li key={file.id}>
                    <a
                      href={file.file}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[var(--primary)] hover:underline"
                    >
                      View File
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          )}
          {submission.reviews && submission.reviews.length > 0 && (
            <div>
              <p className="text-sm sm:text-base text-[var(--foreground)] font-medium">Previous Reviews:</p>
              <ul className="space-y-2">
                {submission.reviews.map((review) => (
                  <li key={review.id} className="text-sm sm:text-base text-[var(--foreground)] border-l-2 border-[var(--primary)] pl-3">
                    <p>
                      <span className="font-medium">Score:</span> {review.score}
                    </p>
                    <p>
                      <span className="font-medium">Comments:</span> {review.comments || "None"}
                    </p>
                    <p>
                      <span className="font-medium">Reviewed At:</span>{" "}
                      {new Date(review.reviewed_at).toLocaleDateString()}
                    </p>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </div>

      {submission.status !== "graded" && (
        <div className="mt-6 bg-[var(--neutral)] p-4 sm:p-6 rounded-xl shadow-md border border-[var(--neutral)]/20">
          <h2 className="text-lg sm:text-xl font-semibold text-[var(--foreground)] mb-4">Submit Review</h2>
          <form onSubmit={handleReviewSubmit} className="space-y-4">
            <div>
              <label htmlFor="score" className="block text-sm sm:text-base font-medium text-[var(--foreground)]">
                Score (0-{submission.challenge.max_score})
              </label>
              <input
                type="number"
                id="score"
                value={score}
                onChange={(e) => setScore(e.target.value)}
                min="0"
                max={submission.challenge.max_score}
                step="0.1"
                required
                className="mt-1 block w-full sm:w-1/3 rounded-md border border-[var(--neutral)]/20 bg-[var(--background)] text-[var(--foreground)] p-2 focus:ring-[var(--primary)] focus:border-[var(--primary)]"
              />
            </div>
            <div>
              <label htmlFor="comments" className="block text-sm sm:text-base font-medium text-[var(--foreground)]">
                Comments
              </label>
              <textarea
                id="comments"
                value={comments}
                onChange={(e) => setComments(e.target.value)}
                rows={4}
                className="mt-1 block w-full rounded-md border border-[var(--neutral)]/20 bg-[var(--background)] text-[var(--foreground)] p-2 focus:ring-[var(--primary)] focus:border-[var(--primary)]"
                placeholder="Provide feedback on the submission"
              />
            </div>
            {reviewError && <p className="text-red-500 text-sm">{reviewError}</p>}
            <button
              type="submit"
              disabled={loading}
              className="bg-[var(--primary)] text-white px-4 sm:px-6 py-2 rounded-md hover:bg-[var(--primary)]/80 text-sm sm:text-base disabled:opacity-50 disabled:pointer-events-none"
            >
              Submit Review
            </button>
          </form>
        </div>
      )}
    </div>
  );
}