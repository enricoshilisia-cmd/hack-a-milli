import Link from "next/link";
import { Challenge } from "@/types/challenge";

interface ChallengeRowProps {
  challenge: Challenge;
}

export default function ChallengeRow({ challenge }: ChallengeRowProps) {
  const { id, title, challenge_type, difficulty, is_published, submission_count } = challenge;

  return (
    <tr className="border-b border-[var(--neutral)]/20 hover:bg-[var(--neutral)]/50">
      <td className="px-2 sm:px-4 py-1 sm:py-2 text-[var(--foreground)] text-xs sm:text-sm truncate">
        <div className="flex items-center gap-2">
          <span>{title}</span>
          {submission_count > 0 && (
            <Link
              href={`/company/challenges/${id}/submissions`}
              className="bg-[var(--primary)] text-white text-xs font-medium px-2 py-1 rounded-full hover:bg-[var(--primary)]/80"
            >
              {submission_count} {submission_count === 1 ? "Submission" : "Submissions"}
            </Link>
          )}
        </div>
      </td>
      <td className="px-2 sm:px-4 py-1 sm:py-2 text-[var(--foreground)]/80 text-xs sm:text-sm truncate">
        {challenge_type.charAt(0).toUpperCase() + challenge_type.slice(1)}
      </td>
      <td className="px-2 sm:px-4 py-1 sm:py-2 text-[var(--foreground)]/80 text-xs sm:text-sm truncate">
        {difficulty.charAt(0).toUpperCase() + difficulty.slice(1)}
      </td>
      <td className="px-2 sm:px-4 py-1 sm:py-2 text-xs sm:text-sm">
        <span className={`font-medium ${is_published ? "text-green-500" : "text-yellow-500"}`}>
          {is_published ? "Published" : "Draft"}
        </span>
      </td>
      <td className="px-2 sm:px-4 py-1 sm:py-2">
        <div className="flex items-center gap-2">
          <Link
            href={`/company/challenges/${id}`}
            className="text-[var(--primary)] text-xs sm:text-sm hover:underline"
          >
            View Details
          </Link>
          {submission_count > 0 && (
            <Link
              href={`/company/challenges/${id}/submissions`}
              className="text-[var(--primary)] text-xs sm:text-sm hover:underline"
            >
              Review Submissions
            </Link>
          )}
        </div>
      </td>
    </tr>
  );
}