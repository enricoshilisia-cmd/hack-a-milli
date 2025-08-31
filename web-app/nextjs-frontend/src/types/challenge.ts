export interface ChallengeCategory {
  id: number;
  name: string;
  description: string;
}

export interface Task {
  id: number;
  title: string;
  description: string;
  order: number; // Position in the challenge
}

export interface Attachment {
  id: number;
  file_url: string;
  file_name: string;
  file_type: string; // e.g., "pdf", "image", etc.
}

export interface Rubric {
  id: number;
  criterion: string;
  description: string;
  max_score: number;
}

export interface Group {
  id: number;
  name: string;
  members: number[]; // Array of user IDs
}

export interface Prerequisite {
  id: number;
  challenge_id: number; // Reference to another challenge
  title: string;
}

export interface Feedback {
  id: number;
  content: string;
  created_by: number; // User ID
  created_at: string;
}

export interface Challenge {
  id: number;
  title: string;
  description: string;
  challenge_type: string;
  difficulty: string;
  visibility: string;
  company: number | null;
  categories: ChallengeCategory[];
  created_by: number | null;
  created_at: string;
  updated_at: string;
  start_date: string | null;
  end_date: string | null;
  duration_minutes: number | null;
  max_submissions: number;
  is_collaborative: boolean;
  max_team_size: number | null;
  skill_tags: string;
  learning_outcomes: string;
  prerequisite_description: string;
  estimated_completion_time: number | null;
  max_score: number;
  is_published: boolean;
  tasks: Task[];
  attachments: Attachment[];
  rubrics: Rubric[];
  groups: Group[];
  prerequisites: Prerequisite[];
  feedback: Feedback[];
  thumbnail: string | null;
  submission_count: number;
}

export interface CategorizedChallenges {
  [category: string]: Challenge[];
}