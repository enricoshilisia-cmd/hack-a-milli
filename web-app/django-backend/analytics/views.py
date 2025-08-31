from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, Count
from django.db.models.functions import TruncMonth, TruncDay
from challenges.models import Challenge
from submissions.models import Submission, SubmissionReview
from badges.models import UserBadge
from users.models import CustomUser, StudentProfile, GraduateProfile
from companies.models import CompanyUser
from challenges.serializers import FeaturedChallengeSerializer
from submissions.serializers import StudentSubmissionSerializer
import logging
logger = logging.getLogger(__name__)

class FeaturedChallengesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List up to 5 featured challenges for students/graduates."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view featured challenges"}, status=status.HTTP_403_FORBIDDEN)
        
        challenges = Challenge.objects.filter(
            is_published=True,
            is_featured=True,
            visibility='public',
            end_date__gte=timezone.now()
        )[:5]
        serializer = FeaturedChallengeSerializer(challenges, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class StudentSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Return summary data for the student/graduate dashboard."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students/graduates can view summary"}, status=status.HTTP_403_FORBIDDEN)
        
        graded = Submission.objects.filter(user=request.user, status='graded')
        total_score = SubmissionReview.objects.filter(submission__user=request.user).aggregate(total=Sum('score'))['total'] or 0
        pending = Submission.objects.filter(user=request.user, status='pending')
        rejected = Submission.objects.filter(user=request.user, status='rejected')
        badges = UserBadge.objects.filter(user=request.user).count()
        
        return Response({
            "total_score": total_score,
            "total_submissions": graded.count() + pending.count() + rejected.count(),
            "badges_earned": badges
        }, status=status.HTTP_200_OK)

class StudentPerformanceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            if request.user.role not in ['student', 'graduate']:
                return Response({"error": "Only students/graduates can view performance"}, status=status.HTTP_403_FORBIDDEN)
            
            # Get current month and year
            now = timezone.now()
            current_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            next_month_start = (current_month_start + timezone.timedelta(days=32)).replace(day=1)
            
            # Fetch daily scores for the current month
            scores = SubmissionReview.objects.filter(
                submission__user=request.user,
                reviewed_at__gte=current_month_start,
                reviewed_at__lt=next_month_start
            ).annotate(
                day=TruncDay('reviewed_at')
            ).values('day').annotate(total=Sum('score')).order_by('day')
            
            scores_data = [{"date": s['day'].strftime('%Y-%m-%d'), "score": s['total']} for s in scores]
            
            # Submissions by category
            submissions = Submission.objects.filter(user=request.user).prefetch_related('challenge__categories')
            category_data = {}
            for sub in submissions:
                for cat in sub.challenge.categories.all():
                    if cat.name not in category_data:
                        category_data[cat.name] = {"count": 0, "total_score": 0}
                    category_data[cat.name]["count"] += 1
                    score = SubmissionReview.objects.filter(submission=sub).aggregate(total=Sum('score'))['total'] or 0
                    category_data[cat.name]["total_score"] += score
            submissions_by_category = [
                {"category": k, "count": v["count"], "total_score": v["total_score"]} for k, v in category_data.items()
            ]
            
            logger.info(f"Performance data for user {request.user.email}: scores={scores_data}, submissions_by_category={submissions_by_category}")
            return Response({
                "aggregation_type": "daily",
                "scores": scores_data,
                "submissions_by_category": submissions_by_category
            }, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error in StudentPerformanceView: {str(e)}")
            return Response({"error": f"Server error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CompanyPerformanceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            if request.user.role != 'company_user':
                return Response({"error": "Only company users can view performance"}, status=status.HTTP_403_FORBIDDEN)
            
            # Get company associated with the user
            try:
                company_user = CompanyUser.objects.get(user=request.user)
                company = company_user.company
            except CompanyUser.DoesNotExist:
                return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)
            
            # Get current month and year
            now = timezone.now()
            current_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            next_month_start = (current_month_start + timezone.timedelta(days=32)).replace(day=1)
            
            # Fetch daily challenge creations for the current month
            challenges = Challenge.objects.filter(
                company=company,
                created_at__gte=current_month_start,
                created_at__lt=next_month_start
            ).annotate(
                day=TruncDay('created_at')
            ).values('day').annotate(count=Count('id')).order_by('day')
            
            challenge_trends = [{"date": c['day'].strftime('%Y-%m-%d'), "count": c['count']} for c in challenges]
            
            # Submissions by category
            submissions = Submission.objects.filter(challenge__company=company).prefetch_related('challenge__categories')
            category_data = {}
            for sub in submissions:
                for cat in sub.challenge.categories.all():
                    if cat.name not in category_data:
                        category_data[cat.name] = {"count": 0}
                    category_data[cat.name]["count"] += 1
            submissions_by_category = [
                {"category": k, "count": v["count"]} for k, v in category_data.items()
            ]
            
            logger.info(f"Performance data for company {company.name}: challenge_trends={challenge_trends}, submissions_by_category={submissions_by_category}")
            return Response({
                "aggregation_type": "daily",
                "challenge_trends": challenge_trends,
                "submissions_by_category": submissions_by_category
            }, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error in CompanyPerformanceView: {str(e)}")
            return Response({"error": f"Server error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class RecentSubmissionsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List up to 3 recent submissions by the student/graduate."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students/graduates can view recent submissions"}, status=status.HTTP_403_FORBIDDEN)
        submissions = Submission.objects.filter(user=request.user).order_by('-submitted_at')[:2]
        serializer = StudentSubmissionSerializer(submissions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class StudentRecommendationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Return actionable recommendations for the student/graduate."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students/graduates can view recommendations"}, status=status.HTTP_403_FORBIDDEN)
        
        recommendations = []
        # Check for incomplete profile skills
        profile = request.user.student_profile if request.user.role == 'student' else request.user.graduate_profile
        if not profile.skills:
            recommendations.append({"action": "Update your skills", "link": "/my_account"})
        
        # Find challenges with nearest deadlines
        now = timezone.now()
        challenges = Challenge.objects.filter(
            is_published=True,
            visibility='public',
            end_date__gt=now
        ).order_by('end_date')[:2]  # Get up to 2 challenges with earliest end_date
        
        if challenges.exists():
            earliest_end_date = challenges.first().end_date
            # Include challenges with the same earliest end_date (up to 2)
            for challenge in challenges:
                if challenge.end_date == earliest_end_date:
                    days_left = (challenge.end_date - now).days
                    recommendations.append({
                        "action": f"Complete '{challenge.title}' (Due in {days_left} day{'s' if days_left != 1 else ''})",
                        "link": f"/challenges/{challenge.id}"
                    })
        
        # Always include job exploration
        recommendations.append({"action": "Explore job opportunities", "link": "/jobs"})
        return Response(recommendations, status=status.HTTP_200_OK)