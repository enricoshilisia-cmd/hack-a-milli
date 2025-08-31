from django.urls import path
from challenges.views import (
    CompanyCreateChallengeView, CompanyChallengeListView, CompanyChallengeSubmissionsView,
    StudentChallengeListView, ChallengeParticipantsView, ChallengeDetailView,
    CategorySearchView
)
from submissions.views import (
    SubmitChallengeView, StudentSubmissionListView, CompanyReviewSubmissionView,
    StudentChallengeResultsView, StudentPendingSubmissionsView, StudentRejectedSubmissionsView
)
from analytics.views import (
    FeaturedChallengesView, StudentSummaryView, StudentPerformanceView,
    RecentSubmissionsView, StudentRecommendationsView, CompanyPerformanceView
)
from .views import CompanyProfileView

urlpatterns = [
    # Company APIs
    path('company/challenges/create/', CompanyCreateChallengeView.as_view(), name='company-create-challenge'),
    path('company/challenges/', CompanyChallengeListView.as_view(), name='company-challenge-list'),
    path('company/challenges/<int:challenge_id>/submissions/', CompanyChallengeSubmissionsView.as_view(), name='company-challenge-submissions'),
    path('company/submissions/<int:submission_id>/review/', CompanyReviewSubmissionView.as_view(), name='company-review-submission'),
    path('company/profile/', CompanyProfileView.as_view(), name='company-profile'),
    path('company/performance/', CompanyPerformanceView.as_view(), name='company-performance'),

    # Student/Graduate APIs
    path('student/challenges/', StudentChallengeListView.as_view(), name='student-challenge-list'),
    path('student/challenges/<int:challenge_id>/', ChallengeDetailView.as_view(), name='challenge-detail'),
    path('student/challenges/<int:challenge_id>/submit/', SubmitChallengeView.as_view(), name='submit-challenge'),
    path('student/submissions/', StudentSubmissionListView.as_view(), name='student-submission-list'),
    path('student/results/', StudentChallengeResultsView.as_view(), name='student-challenge-results'),
    path('student/submissions/pending/', StudentPendingSubmissionsView.as_view(), name='student-pending-submissions'),
    path('student/submissions/rejected/', StudentRejectedSubmissionsView.as_view(), name='student-rejected-submissions'),
    path('challenges/<int:challenge_id>/participants/', ChallengeParticipantsView.as_view(), name='challenge-participants'),
    path('categories/search/', CategorySearchView.as_view(), name='category-search'),

    # Dashboard APIs
    path('student/featured-challenges/', FeaturedChallengesView.as_view(), name='featured-challenges'),
    path('student/summary/', StudentSummaryView.as_view(), name='student-summary'),
    path('student/performance/', StudentPerformanceView.as_view(), name='student-performance'),
    path('student/recent-submissions/', RecentSubmissionsView.as_view(), name='recent-submissions'),
    path('student/recommendations/', StudentRecommendationsView.as_view(), name='student-recommendations'),
]