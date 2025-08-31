from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Submission, SubmissionReview
from .serializers import SubmissionSerializer, StudentSubmissionSerializer, SubmissionReviewSerializer, StudentChallengeResultsSerializer, StudentPendingAndRejectedSerializer
from challenges.models import Challenge
from companies.models import CompanyUser
import logging
logger = logging.getLogger(__name__)

class SubmitChallengeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, challenge_id):
        """Allow students/graduates to submit a challenge."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can submit challenges"}, status=status.HTTP_403_FORBIDDEN)
        try:
            challenge = Challenge.objects.get(id=challenge_id, is_published=True)
            if challenge.end_date and challenge.end_date < timezone.now():
                return Response({"error": "Challenge submission deadline has passed"}, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if user already has a submission for this challenge
            existing_submission = Submission.objects.filter(challenge=challenge, user=request.user).first()
            if existing_submission:
                # Block submission if existing submission is graded or rejected
                if existing_submission.status in ['graded', 'rejected']:
                    return Response({"error": "Cannot submit: Previous submission has been graded or rejected"}, status=status.HTTP_400_BAD_REQUEST)
                # Delete existing pending submission to allow replacement
                existing_submission.delete()
            
            serializer = SubmissionSerializer(data=request.data, context={'request': request})
            if serializer.is_valid():
                serializer.save(user=request.user, challenge=challenge)
                return Response({"message": "Submission successful"}, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Challenge.DoesNotExist:
            return Response({"error": "Challenge not found"}, status=status.HTTP_404_NOT_FOUND)

class StudentSubmissionListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all submissions by the student/graduate."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view their submissions"}, status=status.HTTP_403_FORBIDDEN)
        submissions = Submission.objects.filter(user=request.user)
        serializer = StudentSubmissionSerializer(submissions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class StudentChallengeResultsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List scores for all challenges submitted by the student/graduate."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view their challenge results"}, status=status.HTTP_403_FORBIDDEN)
        submissions = Submission.objects.filter(
            user=request.user,
            status='graded',
            reviews__isnull=False
        ).prefetch_related('reviews').distinct()
        serializer = StudentChallengeResultsSerializer(submissions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class StudentPendingSubmissionsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all pending submissions by the student/graduate."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view their pending submissions"}, status=status.HTTP_403_FORBIDDEN)
        submissions = Submission.objects.filter(
            user=request.user,
            status='pending'
        )
        serializer = StudentPendingAndRejectedSerializer(submissions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class StudentRejectedSubmissionsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all rejected submissions by the student/graduate."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view their rejected submissions"}, status=status.HTTP_403_FORBIDDEN)
        submissions = Submission.objects.filter(
            user=request.user,
            status='rejected'
        )
        serializer = StudentPendingAndRejectedSerializer(submissions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class CompanyReviewSubmissionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, submission_id):
        """Allow company users to review a submission."""
        logger.debug(f"Received review request for submission_id: {submission_id}, data: {request.data}")
        if request.user.role not in ['company_user']:
            return Response({"error": "Only company users can review submissions"}, status=status.HTTP_403_FORBIDDEN)
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            submission = Submission.objects.get(id=submission_id, challenge__company=company_user.company)
            logger.debug(f"Submission found: {submission.id}, status: {submission.status}")
            serializer = SubmissionReviewSerializer(data=request.data, context={'submission': submission})
            if serializer.is_valid():
                serializer.save(submission=submission, reviewer=request.user)
                submission.status = 'graded'
                submission.save()
                logger.debug(f"Review saved, updated submission status to 'graded' for submission_id: {submission_id}")
                return Response({"message": "Review submitted successfully"}, status=status.HTTP_201_CREATED)
            logger.error(f"Serializer errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except CompanyUser.DoesNotExist:
            logger.error("User is not associated with any company")
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)
        except Submission.DoesNotExist:
            logger.error("Submission not found or not owned by company")
            return Response({"error": "Submission not found or not owned by your company"}, status=status.HTTP_404_NOT_FOUND)