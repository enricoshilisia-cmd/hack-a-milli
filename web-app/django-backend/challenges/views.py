from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Challenge, ChallengeCategory
from .serializers import ChallengeSerializer, StudentChallengeSerializer, ChallengeCategorySerializer
from submissions.models import Submission
from submissions.serializers import SubmissionSerializer, ParticipantSerializer
from users.models import CustomUser, StudentProfile, GraduateProfile
from companies.models import CompanyUser

class CompanyCreateChallengeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Allow companies to create a challenge."""
        if request.user.role != 'company_user':
            return Response({"error": "Only company users can create challenges"}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            company = company_user.company
        except CompanyUser.DoesNotExist:
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ChallengeSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save(created_by=request.user, company=company)
            return Response({"message": "Challenge created successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CompanyChallengeListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List all challenges created by the company, grouped by category."""
        if request.user.role != 'company_user':
            return Response({"error": "Only company users can view their challenges"}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            company = company_user.company
        except CompanyUser.DoesNotExist:
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)

        challenges = Challenge.objects.filter(company=company).prefetch_related('categories')
        categorized_challenges = {}
        for challenge in challenges:
            challenge_data = ChallengeSerializer(challenge).data
            for category in challenge_data['categories']:
                category_name = category['name']
                if category_name not in categorized_challenges:
                    categorized_challenges[category_name] = []
                categorized_challenges[category_name].append(challenge_data)

        return Response(categorized_challenges, status=status.HTTP_200_OK)

class CompanyChallengeSubmissionsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, challenge_id):
        """List all submissions for a specific challenge."""
        if request.user.role != 'company_user':
            return Response({"error": "Only company users can view submissions"}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            company = company_user.company
        except CompanyUser.DoesNotExist:
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            challenge = Challenge.objects.get(id=challenge_id, company=company)
            submissions = Submission.objects.filter(challenge=challenge)
            serializer = SubmissionSerializer(submissions, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Challenge.DoesNotExist:
            return Response({"error": "Challenge not found or not owned by your company"}, status=status.HTTP_404_NOT_FOUND)

class StudentChallengeListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """List challenges for students/graduates based on their areas of expertise or challenge type, grouped by category or type."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view challenges"}, status=status.HTTP_403_FORBIDDEN)

        # Base query for public, published challenges
        challenges = Challenge.objects.filter(
            is_published=True,
            visibility='public',
            end_date__gte=timezone.now()
        ).prefetch_related('categories')
        
        # Filter by areas_of_expertise
        areas_of_expertise = []
        if request.user.role == 'student':
            try:
                profile = StudentProfile.objects.get(user=request.user)
                areas_of_expertise = [category.name for category in profile.areas_of_expertise.all()]
            except StudentProfile.DoesNotExist:
                areas_of_expertise = []  # Default to empty list if no profile
        elif request.user.role == 'graduate':
            try:
                profile = GraduateProfile.objects.get(user=request.user)
                areas_of_expertise = [category.name for category in profile.areas_of_expertise.all()]
            except GraduateProfile.DoesNotExist:
                areas_of_expertise = []

        if areas_of_expertise:
            challenges = challenges.filter(categories__name__in=areas_of_expertise)

        # Filter by challenge_type if provided
        challenge_type = request.query_params.get('challenge_type')
        if challenge_type:
            valid_types = [choice[0] for choice in Challenge.TYPE_CHOICES]
            if challenge_type in valid_types:
                challenges = challenges.filter(challenge_type=challenge_type)
            else:
                return Response({"error": f"Invalid challenge_type. Valid types: {valid_types}"}, status=status.HTTP_400_BAD_REQUEST)

        # Group by category or challenge_type
        group_by = request.query_params.get('group_by', 'category')
        if group_by not in ['category', 'type']:
            return Response({"error": "group_by must be 'category' or 'type'"}, status=status.HTTP_400_BAD_REQUEST)

        categorized_challenges = {}
        if group_by == 'category':
            for challenge in challenges:
                challenge_data = StudentChallengeSerializer(challenge).data
                for category in challenge_data['categories']:
                    category_name = category['name']
                    if category_name not in categorized_challenges:
                        categorized_challenges[category_name] = []
                    categorized_challenges[category_name].append(challenge_data)
        else:  # group_by == 'type'
            for challenge in challenges:
                challenge_data = StudentChallengeSerializer(challenge).data
                challenge_type = challenge_data['challenge_type']
                if challenge_type not in categorized_challenges:
                    categorized_challenges[challenge_type] = []
                categorized_challenges[challenge_type].append(challenge_data)

        return Response(categorized_challenges, status=status.HTTP_200_OK)

class ChallengeParticipantsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, challenge_id):
        """List participants of a challenge (anonymized for students)."""
        if request.user.role not in ['student', 'graduate', 'company_user']:
            return Response({"error": "Only students, graduates, or company users can view participants"}, status=status.HTTP_403_FORBIDDEN)
        try:
            challenge = Challenge.objects.get(id=challenge_id, is_published=True)
            submissions = Submission.objects.filter(challenge=challenge)
            participants = CustomUser.objects.filter(id__in=submissions.values('user_id'))
            serializer = ParticipantSerializer(participants, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Challenge.DoesNotExist:
            return Response({"error": "Challenge not found"}, status=status.HTTP_404_NOT_FOUND)
        

class ChallengeDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, challenge_id):
        """Retrieve details of a specific challenge for students/graduates."""
        if request.user.role not in ['student', 'graduate']:
            return Response({"error": "Only students or graduates can view challenge details"}, status=status.HTTP_403_FORBIDDEN)

        try:
            challenge = Challenge.objects.filter(
                id=challenge_id,
                is_published=True,
                visibility='public',
                end_date__gte=timezone.now()
            ).prefetch_related('categories').first()

            if not challenge:
                return Response({"error": "Challenge not found or not available"}, status=status.HTTP_404_NOT_FOUND)

            # Check if user's areas_of_expertise match challenge categories
            areas_of_expertise = []
            if request.user.role == 'student':
                try:
                    profile = StudentProfile.objects.get(user=request.user)
                    areas_of_expertise = [category.name for category in profile.areas_of_expertise.all()]
                except StudentProfile.DoesNotExist:
                    areas_of_expertise = []
            elif request.user.role == 'graduate':
                try:
                    profile = GraduateProfile.objects.get(user=request.user)
                    areas_of_expertise = [category.name for category in profile.areas_of_expertise.all()]
                except GraduateProfile.DoesNotExist:
                    areas_of_expertise = []

            if areas_of_expertise and not challenge.categories.filter(name__in=areas_of_expertise).exists():
                return Response({"error": "Challenge not available for your areas of expertise"}, status=status.HTTP_403_FORBIDDEN)

            serializer = StudentChallengeSerializer(challenge)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Challenge.DoesNotExist:
            return Response({"error": "Challenge not found"}, status=status.HTTP_404_NOT_FOUND)
        
class CategorySearchView(APIView):
    def get(self, request):
        """Search for ChallengeCategory names based on a query string."""
        query = request.query_params.get('q', '')
        if not query:  # Return all categories if query is empty
            categories = ChallengeCategory.objects.all()[:100]  # Limit to 100 to prevent excessive data
        else:
            if len(query) < 4:
                return Response({"categories": []}, status=status.HTTP_200_OK)
            categories = ChallengeCategory.objects.filter(name__istartswith=query)[:10]  # Limit to 10 results for search
        serializer = ChallengeCategorySerializer(categories, many=True)  # Use serializer with id, name, description
        return Response({"categories": serializer.data}, status=status.HTTP_200_OK)