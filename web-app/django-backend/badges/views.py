from django.db.models import Sum
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Badge, UserBadge
from .serializers import BadgeSerializer, UserBadgeSerializer
from submissions.models import Submission, SubmissionReview
from submissions.serializers import SubmissionReviewSerializer
from users.models import CustomUser
from companies.models import CompanyUser
from django.db.models.signals import post_save
from django.dispatch import receiver

class BadgeListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all available badges."""
        badges = Badge.objects.all()
        serializer = BadgeSerializer(badges, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class UserBadgeListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all badges earned by the authenticated user."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view their badges"}, status=status.HTTP_403_FORBIDDEN)
        user_badges = UserBadge.objects.filter(user=request.user)
        serializer = UserBadgeSerializer(user_badges, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

@receiver(post_save, sender=SubmissionReview)
def assign_badges(sender, instance, created, **kwargs):
    """Automatically assign badges based on cumulative score from all companies after a submission is reviewed."""
    if created:
        user = instance.submission.user
        total_score = SubmissionReview.objects.filter(
            submission__user=user
        ).aggregate(total=Sum('score'))['total'] or 0

        # Define badge thresholds
        badge_thresholds = [
            {'name': 'Beginner', 'threshold': 100},
            {'name': 'Intermediate', 'threshold': 500},
            {'name': 'Expert', 'threshold': 1000},
        ]

        for badge_data in badge_thresholds:
            if total_score >= badge_data['threshold']:
                badge, _ = Badge.objects.get_or_create(
                    name=badge_data['name'],
                    defaults={
                        'description': f"Awarded for achieving {badge_data['threshold']} points across all challenges",
                        'criteria': f"Total score >= {badge_data['threshold']}"
                    }
                )
                UserBadge.objects.get_or_create(
                    user=user,
                    badge=badge,
                    defaults={'evidence': instance.submission}
                )

class CompanyScoreSubmissionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, submission_id):
        """Allow company users to score a submission."""
        if request.user.role != 'company_user':
            return Response({"error": "Only company users can score submissions"}, status=status.HTTP_403_FORBIDDEN)
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            submission = Submission.objects.get(id=submission_id, challenge__company=company_user.company)
            serializer = SubmissionReviewSerializer(data=request.data, context={'submission': submission})
            if serializer.is_valid():
                serializer.save(submission=submission, reviewer=request.user)
                submission.status = 'graded'
                submission.save()
                return Response({"message": "Submission scored successfully"}, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except CompanyUser.DoesNotExist:
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)
        except Submission.DoesNotExist:
            return Response({"error": "Submission not found or not owned by your company"}, status=status.HTTP_404_NOT_FOUND)