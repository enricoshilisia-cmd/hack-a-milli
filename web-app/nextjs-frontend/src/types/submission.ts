export interface SubmissionFile {
  id: number;
  file: string;
  submission: number;
}

export interface SubmissionReview {
  id: number;
  submission: number;
  reviewer: number | null;
  comments: string;
  score: number;
  reviewed_at: string;
}

export interface Submission {
  id: number;
  user: {
    id: number;
    email: string;
  };
  challenge: {
    id: number;
    title: string;
    max_score: number;
  };
  repo_link: string;
  submitted_at: string;
  status: 'pending' | 'graded' | 'rejected';
  files: SubmissionFile[];
  reviews: SubmissionReview[];
}