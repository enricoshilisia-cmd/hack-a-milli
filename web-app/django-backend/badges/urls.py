from django.urls import path
from .views import BadgeListView, UserBadgeListView, CompanyScoreSubmissionView

urlpatterns = [
    path('badges/', BadgeListView.as_view(), name='badge-list'),
    path('my-badges/', UserBadgeListView.as_view(), name='user-badge-list'),
    path('submissions/<int:submission_id>/score/', CompanyScoreSubmissionView.as_view(), name='company-score-submission'),
]