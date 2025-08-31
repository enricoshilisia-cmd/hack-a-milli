from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from .serializers import (
    StudentProfileSerializer, CompanyProfileSerializer,
    MentorProfileSerializer, AdminProfileSerializer,
    PendingSchoolDomainSerializer, PendingCompanyDomainSerializer,
    LoginSerializer, GraduateProfileSerializer,
    StudentProfileUpdateSerializer, GraduateProfileUpdateSerializer
)
from .models import CustomUser, PendingSchoolDomain, PendingCompanyDomain, StudentProfile, GraduateProfile, CompanyProfile
from universities.models import University, StudentEnrollment
from companies.models import Company, CompanyUser
from rest_framework.permissions import IsAuthenticated
from challenges.models import ChallengeCategory
import logging

# Set up logging
logger = logging.getLogger(__name__)

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in ['student', 'graduate', 'company_user']:
            return Response({"error": "Only students, graduates, and company users can access profiles"}, status=status.HTTP_403_FORBIDDEN)

        try:
            if user.role == 'student':
                profile = StudentProfile.objects.get(user=user)
                serializer = StudentProfileSerializer(profile)
            elif user.role == 'graduate':
                profile = GraduateProfile.objects.get(user=user)
                serializer = GraduateProfileSerializer(profile)
            else:  # company_user
                profile = CompanyProfile.objects.get(user=user)
                serializer = CompanyProfileSerializer(profile)

            data = serializer.data
            if user.role in ['student', 'graduate']:
                areas_of_expertise_ids = data.get('areas_of_expertise', [])
                categories = ChallengeCategory.objects.filter(id__in=areas_of_expertise_ids)
                data['areas_of_expertise'] = [category.name for category in categories]
                data['profile_image'] = profile.profile_image.url if profile.profile_image else None
            data['user'] = {
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'phone_number': user.phone_number,
            }
            return Response(data, status=status.HTTP_200_OK)
        except (StudentProfile.DoesNotExist, GraduateProfile.DoesNotExist, CompanyProfile.DoesNotExist):
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)

class StudentRegisterView(APIView):
    @csrf_exempt
    def post(self, request):
        logger.debug(f"Student registration request: {request.data}")
        serializer = StudentProfileSerializer(data=request.data)
        if serializer.is_valid():
            profile = serializer.save()
            message = "Student account created"
            if not profile.user.is_verified:
                message += ", pending domain verification"
            return Response({"message": message}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class GraduateRegisterView(APIView):
    @csrf_exempt
    def post(self, request):
        logger.debug(f"Graduate registration request: {request.data}")
        serializer = GraduateProfileSerializer(data=request.data)
        if serializer.is_valid():
            profile = serializer.save()
            return Response({"message": "Graduate account created successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CompanyRegisterView(APIView):
    @csrf_exempt
    def post(self, request):
        logger.debug(f"Company registration request: {request.data}")
        serializer = CompanyProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Company account created, pending domain verification"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MentorRegisterView(APIView):
    @csrf_exempt
    def post(self, request):
        logger.debug(f"Mentor registration request: {request.data}")
        serializer = MentorProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Mentor account created successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AdminRegisterView(APIView):
    @csrf_exempt
    def post(self, request):
        logger.debug(f"Admin registration request: {request.data}")
        serializer = AdminProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Admin account created successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    @csrf_exempt
    def post(self, request):
        logger.debug(f"Login request: {request.data}")
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            token, created = Token.objects.get_or_create(user=user)
            user_data = {
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "role": user.role,
                "is_verified": user.is_verified,
            }
            if hasattr(user, 'student_profile'):
                student_profile = user.student_profile
                user_data.update({
                    "university_name": student_profile.university_name,
                    "graduation_year": student_profile.graduation_year,
                    "skills": student_profile.skills,
                })
            elif hasattr(user, 'graduate_profile'):
                graduate_profile = user.graduate_profile
                user_data.update({
                    "university_name": graduate_profile.university_name,
                    "graduation_year": graduate_profile.graduation_year,
                    "skills": graduate_profile.skills,
                })
            return Response({
                "token": token.key,
                "user": user_data
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PendingSchoolDomainListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin':
            return Response({"error": "Admin access required"}, status=status.HTTP_403_FORBIDDEN)
        domains = PendingSchoolDomain.objects.all()
        serializer = PendingSchoolDomainSerializer(domains, many=True)
        return Response(serializer.data)

class PendingSchoolDomainApproveView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        if request.user.role != 'admin':
            return Response({"error": "Admin access required"}, status=status.HTTP_403_FORBIDDEN)
        try:
            with transaction.atomic():
                pending_domain = PendingSchoolDomain.objects.get(pk=pk)
                if pending_domain.status != 'pending':
                    return Response({"error": "Domain not pending"}, status=status.HTTP_400_BAD_REQUEST)
                university, created = University.objects.get_or_create(
                    domain=pending_domain.domain,
                    defaults={
                        'name': pending_domain.university_name,
                        'location': request.data.get('location', 'Unknown'),
                        'is_verified': True
                    }
                )
                if not created:
                    university.is_verified = True
                    university.save()
                submitting_user = pending_domain.submitted_by
                if not submitting_user.is_verified:
                    submitting_user.is_verified = True
                    submitting_user.save(update_fields=['is_verified'])
                StudentEnrollment.objects.get_or_create(
                    student=submitting_user,
                    university=university,
                    defaults={'enrollment_date': request.data.get('enrollment_date', '2025-01-01')}
                )
                domain_part = f"@{pending_domain.domain}"
                students = CustomUser.objects.filter(
                    email__endswith=domain_part,
                    role='student',
                    is_verified=False
                )
                verified_count = students.update(is_verified=True)
                pending_domain.status = 'approved'
                pending_domain.save()
                return Response({
                    "message": "Domain approved and students verified",
                    "verified_count": verified_count
                }, status=status.HTTP_200_OK)
        except PendingSchoolDomain.DoesNotExist:
            return Response({"error": "Pending domain not found"}, status=status.HTTP_404_NOT_FOUND)

class PendingCompanyDomainListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin':
            return Response({"error": "Admin access required"}, status=status.HTTP_403_FORBIDDEN)
        domains = PendingCompanyDomain.objects.all()
        serializer = PendingCompanyDomainSerializer(domains, many=True)
        return Response(serializer.data)

class PendingCompanyDomainApproveView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        if request.user.role != 'admin':
            return Response({"error": "Admin access required"}, status=status.HTTP_403_FORBIDDEN)
        try:
            with transaction.atomic():
                pending_domain = PendingCompanyDomain.objects.get(pk=pk)
                if pending_domain.status != 'pending':
                    return Response({"error": "Domain not pending"}, status=status.HTTP_400_BAD_REQUEST)
                pending_domain.status = 'approved'
                pending_domain.save()
                company = Company.objects.create(
                    name=pending_domain.company_name,
                    industry=pending_domain.industry,
                    website=pending_domain.website,
                    domain=pending_domain.domain,
                    verified=True
                )
                user = pending_domain.submitted_by
                if not user.is_verified:
                    user.is_verified = True
                    user.save(update_fields=['is_verified'])
                CompanyUser.objects.create(
                    company=company,
                    user=user,
                    role_in_company=request.data.get('role_in_company', 'recruiter')
                )
                company_profile = user.company_profile
                company_profile.verification_status = 'verified'
                company_profile.save()
                return Response({"message": "Domain approved and user verified"}, status=status.HTTP_200_OK)
        except PendingCompanyDomain.DoesNotExist:
            return Response({"error": "Pending domain not found"}, status=status.HTTP_404_NOT_FOUND)

class ProfileUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        logger.debug(f"Profile update request data: {request.data}")
        user = request.user
        if user.role not in ['student', 'graduate']:
            return Response({"error": "Only students and graduates can update profiles"}, status=status.HTTP_403_FORBIDDEN)

        try:
            with transaction.atomic():
                if user.role == 'student':
                    serializer = StudentProfileUpdateSerializer(
                        user.student_profile,
                        data=request.data,
                        context={'request': request},
                        partial=True
                    )
                else:
                    serializer = GraduateProfileUpdateSerializer(
                        user.graduate_profile,
                        data=request.data,
                        context={'request': request},
                        partial=True
                    )

                if serializer.is_valid():
                    profile = serializer.save()
                    logger.debug(f"Profile updated successfully for user: {user.email}, areas_of_expertise: {profile.areas_of_expertise.all()}")
                    return Response({"message": "Profile updated successfully"}, status=status.HTTP_200_OK)
                logger.error(f"Serializer errors: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except (StudentProfile.DoesNotExist, GraduateProfile.DoesNotExist):
            logger.error(f"Profile not found for user: {user.email}")
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)