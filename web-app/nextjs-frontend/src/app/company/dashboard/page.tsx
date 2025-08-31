"use client";

import { useState, useEffect } from "react";
import { useAuthStore } from "@/hooks/useAuth";
import api from "@/lib/api";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import Link from "next/link";
import { useRouter } from "next/navigation";

interface Challenge {
  id: number;
  title: string;
  description: string;
  challenge_type: string;
  difficulty: string;
  start_date: string | null;
  end_date: string | null;
  is_published: boolean;
}

interface CategorizedChallenges {
  [category: string]: Challenge[];
}

interface CompanyProfile {
  company_name: string;
  industry: string;
  website: string;
  verification_status: string;
}

interface Submission {
  id: number;
  challenge: number;
  status: string;
}

interface DashboardStats {
  totalChallenges: number;
  activeChallenges: number;
  upcomingChallenges: number;
  expiredChallenges: number;
  totalSubmissions: number;
  pendingReviews: number;
}

interface ChallengeTrend {
  date: string;
  count: number;
}

interface SubmissionDistribution {
  category: string;
  count: number;
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

export default function CompanyDashboard() {
  const { user, isAuthenticated, getAuthState } = useAuthStore();
  const router = useRouter();
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [categorizedChallenges, setCategorizedChallenges] = useState<CategorizedChallenges>({});
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [allChallenges, setAllChallenges] = useState<Challenge[]>([]);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [allSubmissions, setAllSubmissions] = useState<Submission[]>([]);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [profile, setProfile] = useState<CompanyProfile | null>(null);
  const [stats, setStats] = useState<DashboardStats>({
    totalChallenges: 0,
    activeChallenges: 0,
    upcomingChallenges: 0,
    expiredChallenges: 0,
    totalSubmissions: 0,
    pendingReviews: 0,
  });
  const [challengeTrends, setChallengeTrends] = useState<ChallengeTrend[]>([]);
  const [submissionDistribution, setSubmissionDistribution] = useState<SubmissionDistribution[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Check auth state synchronously on mount
  useEffect(() => {
    const { isAuthenticated: auth, user } = getAuthState();
    if (!auth || user?.role !== "company_user") {
      router.push("/auth/login");
      return;
    }
  }, [getAuthState, router]);

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "company_user") return;

    const fetchData = async () => {
      setLoading(true);
      try {
        // Fetch company challenges (categorized)
        const challengesResponse = await api.get("/companies/company/challenges/", {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        const challengesData: CategorizedChallenges = challengesResponse.data;
        setCategorizedChallenges(challengesData);

        // Flatten challenges and remove duplicates by id
        const flatChallenges: Challenge[] = [];
        const seenIds = new Set<number>();
        Object.values(challengesData).flat().forEach((challenge) => {
          if (!seenIds.has(challenge.id)) {
            flatChallenges.push(challenge);
            seenIds.add(challenge.id);
          }
        });
        setAllChallenges(flatChallenges);

        // Compute challenge stats
        const now = new Date();
        const active = flatChallenges.filter((ch) => {
          const start = ch.start_date ? new Date(ch.start_date) : null;
          const end = ch.end_date ? new Date(ch.end_date) : null;
          return ch.is_published && start && end && start <= now && now <= end;
        }).length;
        const upcoming = flatChallenges.filter((ch) => {
          const start = ch.start_date ? new Date(ch.start_date) : null;
          return ch.is_published && start && start > now;
        }).length;
        const expired = flatChallenges.filter((ch) => {
          const end = ch.end_date ? new Date(ch.end_date) : null;
          return ch.is_published && end && end < now;
        }).length;

        // Fetch submissions for all challenges
        let submissions: Submission[] = [];
        let pending = 0;
        for (const challenge of flatChallenges) {
          const subsResponse = await api.get(`/companies/company/challenges/${challenge.id}/submissions/`, {
            headers: { Authorization: `Token ${localStorage.getItem("token")}` },
          });
          const challengeSubs: Submission[] = subsResponse.data;
          submissions = [...submissions, ...challengeSubs];
          pending += challengeSubs.filter((sub) => sub.status === 'pending').length;
        }
        setAllSubmissions(submissions);

        // Update stats
        setStats({
          totalChallenges: flatChallenges.length,
          activeChallenges: active,
          upcomingChallenges: upcoming,
          expiredChallenges: expired,
          totalSubmissions: submissions.length,
          pendingReviews: pending,
        });

        // Fetch company performance data (daily challenge trends and submissions by category)
        const performanceResponse = await api.get("/companies/company/performance/", {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        const performanceData = performanceResponse.data;
        // Transform daily challenge trends for the chart
        const dailyTrends = performanceData.challenge_trends.map((trend: ChallengeTrend) => ({
          name: new Date(trend.date).toLocaleString('default', { day: 'numeric', month: 'short' }),
          value: trend.count,
        }));
        setChallengeTrends(dailyTrends);

        // Submission distribution by category
        setSubmissionDistribution(performanceData.submissions_by_category.map((item: SubmissionDistribution) => ({
          name: item.category,
          value: item.count,
        })));

        // Fetch company profile
        const profileResponse = await api.get("/users/profile/", {
          headers: { Authorization: `Token ${localStorage.getItem("token")}` },
        });
        setProfile(profileResponse.data);
      } catch (err: unknown) {
        if (err && typeof err === "object" && "message" in err) {
          setError((err as { message?: string }).message || "Failed to load dashboard data");
        } else {
          setError("Failed to load dashboard data");
        }
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [isAuthenticated, user]);

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center px-4 py-8">
        <p className="text-lg sm:text-xl text-[var(--foreground)] text-center">Loading dashboard...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center px-4 py-8">
        <p className="text-lg sm:text-xl text-red-500 text-center">Error: {error}</p>
      </div>
    );
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8 pt-8 pb-4 sm:pb-6">
      <header className="mb-4 sm:mb-6">
        <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-[var(--foreground)]">
          {getGreeting()}, {user?.last_name || user?.email}
        </h1>
        <p className="text-sm sm:text-base text-[var(--foreground)]/70 mt-2">Welcome to your company&apos;s dashboard. Here&apos;s a quick overview.</p>
      </header>

      {/* Stats Overview */}
      <section className="flex flex-row overflow-x-auto sm:grid sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-6 mb-4 sm:mb-6 snap-x snap-mandatory">
        <div className="bg-[var(--neutral)] p-2 sm:p-4 lg:p-6 rounded-xl shadow-md min-w-[100px] sm:min-w-0 snap-center border border-[var(--neutral)]/20 hover:border-[var(--primary)] hover:shadow-lg hover:shadow-[var(--primary)]/50 hover:scale-105 transition-all duration-300 sm:hover:scale-100 sm:hover:shadow-md">
          <h3 className="text-xs sm:text-base lg:text-lg font-semibold text-[var(--foreground)] truncate">
            <span className="sm:hidden">Total</span>
            <span className="hidden sm:block">Total Challenges</span>
          </h3>
          <p className="text-base sm:text-xl lg:text-2xl font-bold text-[var(--primary)]">{stats.totalChallenges}</p>
        </div>
        <div className="bg-[var(--neutral)] p-2 sm:p-4 lg:p-6 rounded-xl shadow-md min-w-[100px] sm:min-w-0 snap-center border border-[var(--neutral)]/20 hover:border-[var(--primary)] hover:shadow-lg hover:shadow-[var(--primary)]/50 hover:scale-105 transition-all duration-300 sm:hover:scale-100 sm:hover:shadow-md">
          <h3 className="text-xs sm:text-base lg:text-lg font-semibold text-[var(--foreground)] truncate">
            <span className="sm:hidden">Active</span>
            <span className="hidden sm:block">Active Challenges</span>
          </h3>
          <p className="text-base sm:text-xl lg:text-2xl font-bold text-green-500">{stats.activeChallenges}</p>
        </div>
        <div className="bg-[var(--neutral)] p-2 sm:p-4 lg:p-6 rounded-xl shadow-md min-w-[100px] sm:min-w-0 snap-center border border-[var(--neutral)]/20 hover:border-[var(--primary)] hover:shadow-lg hover:shadow-[var(--primary)]/50 hover:scale-105 transition-all duration-300 sm:hover:scale-100 sm:hover:shadow-md">
          <h3 className="text-xs sm:text-base lg:text-lg font-semibold text-[var(--foreground)] truncate">
            <span className="sm:hidden">Pending</span>
            <span className="hidden sm:block">Pending Reviews</span>
          </h3>
          <p className="text-base sm:text-xl lg:text-2xl font-bold text-yellow-500">{stats.pendingReviews}</p>
        </div>
        <div className="bg-[var(--neutral)] p-2 sm:p-4 lg:p-6 rounded-xl shadow-md min-w-[100px] sm:min-w-0 snap-center border border-[var(--neutral)]/20 hover:border-[var(--primary)] hover:shadow-lg hover:shadow-[var(--primary)]/50 hover:scale-105 transition-all duration-300 sm:hover:scale-100 sm:hover:shadow-md">
          <h3 className="text-xs sm:text-base lg:text-lg font-semibold text-[var(--foreground)] truncate">
            <span className="sm:hidden">Submissions</span>
            <span className="hidden sm:block">Total Submissions</span>
          </h3>
          <p className="text-base sm:text-xl lg:text-2xl font-bold text-blue-500">{stats.totalSubmissions}</p>
        </div>
      </section>

      {/* Graphs Section */}
      <section className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6 mb-4 sm:mb-6">
        <div className="bg-[var(--neutral)] p-4 sm:p-6 rounded-xl shadow-md">
          <h2 className="text-lg sm:text-xl font-semibold text-[var(--foreground)] mb-4">Challenge Creation Trends (This Month)</h2>
          <ResponsiveContainer width="100%" height={250} className="min-h-[200px] sm:min-h-[250px]">
            <LineChart data={challengeTrends}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" fontSize={12} angle={-45} textAnchor="end" interval={0} />
              <YAxis fontSize={12} />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="value"
                stroke="#8884d8"
                strokeWidth={2}
                name="Challenges Created"
                dot={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-[var(--neutral)] p-4 sm:p-6 rounded-xl shadow-md">
          <h2 className="text-lg sm:text-xl font-semibold text-[var(--foreground)] mb-4">Submissions by Category</h2>
          <ResponsiveContainer width="100%" height={250} className="min-h-[200px] sm:min-h-[250px]">
            <PieChart>
              <Pie
                data={submissionDistribution}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                outerRadius={80}
                fill="#8884d8"
                label={{ fontSize: 12 }}
              >
                {submissionDistribution.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend wrapperStyle={{ fontSize: 12 }} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </section>

      {/* Quick Actions */}
      <section className="bg-[var(--neutral)] p-4 sm:p-6 rounded-xl shadow-md mb-4 sm:mb-6">
        <h2 className="text-lg sm:text-xl font-semibold text-[var(--foreground)] mb-4">Quick Actions</h2>
        <div className="flex flex-col sm:flex-row sm:flex-wrap gap-3 sm:gap-4">
          <Link
            href="/company/challenges/create"
            className="bg-[var(--primary)] text-white px-4 py-2 rounded-md hover:bg-[var(--primary)]/80 text-sm sm:text-base text-center"
          >
            Create New Challenge
          </Link>
          <Link
            href="/company/challenges"
            className="bg-[var(--secondary)] text-white px-4 py-2 rounded-md hover:bg-[var(--secondary)]/80 text-sm sm:text-base text-center"
          >
            View All Challenges
          </Link>
          <Link
            href="/company/profile"
            className="bg-gray-500 text-white px-4 py-2 rounded-md hover:bg-gray-600 text-sm sm:text-base text-center"
          >
            Edit Profile
          </Link>
        </div>
      </section>

      {/* Recent Challenges */}
      <section className="bg-[var(--neutral)] p-4 sm:p-6 rounded-xl shadow-md">
        <h2 className="text-lg sm:text-xl font-semibold text-[var(--foreground)] mb-4">Recent Challenges</h2>
        {allChallenges.length > 0 ? (
          <ul className="space-y-4">
            {allChallenges.slice(0, 5).map((challenge) => (
              <li key={challenge.id} className="border-b border-[var(--neutral)]/20 pb-2">
                <h3 className="text-base sm:text-lg font-medium text-[var(--foreground)] truncate">{challenge.title}</h3>
                <p className="text-sm sm:text-base text-[var(--foreground)]/80 line-clamp-2">{challenge.description}</p>
                <p className="text-xs sm:text-sm text-[var(--foreground)]/60">
                  Type: {challenge.challenge_type} | Difficulty: {challenge.difficulty}
                </p>
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-sm sm:text-base text-[var(--foreground)]/80">No challenges found.</p>
        )}
      </section>
    </div>
  );
}