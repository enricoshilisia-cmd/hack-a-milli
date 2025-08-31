from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth import authenticate
from django.db import transaction
from .models import PendingSchoolDomain, PendingCompanyDomain, StudentProfile, CompanyProfile, MentorProfile, AdminProfile, GraduateProfile
from universities.models import University, StudentEnrollment
from companies.models import Company
from challenges.models import ChallengeCategory
from django.core.exceptions import ValidationError
from .utils import validate_user_domain

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password', 'role', 'first_name', 'last_name', 'phone_number']
        extra_kwargs = {
            'password': {'write_only': True, 'required': False},
            'role': {'required': True},
            'email': {'required': False},
            'first_name': {'required': False},
            'last_name': {'required': False},
            'phone_number': {'required': False, 'allow_blank': True},
        }

    def create(self, validated_data):
        return User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data['role'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone_number=validated_data.get('phone_number', '')
        )

    def update(self, instance, validated_data):
        if 'email' in validated_data:
            new_email = validated_data['email'].lower()
            if instance.role == 'student':
                domain = new_email.split('@')[-1]
                if not University.objects.filter(domain=domain, is_verified=True).exists():
                    raise serializers.ValidationError({"email": "Student email must use a verified university domain."})
            instance.email = new_email

        if 'password' in validated_data:
            instance.set_password(validated_data['password'])

        for attr, value in validated_data.items():
            if attr != 'password':
                setattr(instance, attr, value)

        instance.save()
        return instance

class StudentProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    university_domain = serializers.CharField(write_only=True)
    areas_of_expertise = serializers.PrimaryKeyRelatedField(
        queryset=ChallengeCategory.objects.all(),
        many=True,
        required=False,
        allow_empty=True
    )

    class Meta:
        model = StudentProfile
        fields = ['user', 'university_name', 'university_domain', 'graduation_year', 'skills', 'areas_of_expertise']

    def create(self, validated_data):
        with transaction.atomic():
            user_data = validated_data.pop('user')
            university_domain = validated_data.pop('university_domain').lower()
            university_name = validated_data['university_name']
            areas_of_expertise = validated_data.pop('areas_of_expertise', [])

            user = UserSerializer().create(user_data)

            try:
                university = University.objects.get(domain=university_domain, is_verified=True)
                user.is_verified = True
                user.save(update_fields=['is_verified'])
                StudentEnrollment.objects.get_or_create(
                    student=user,
                    university=university,
                    defaults={'enrollment_date': '2025-01-01'}
                )
            except University.DoesNotExist:
                PendingSchoolDomain.objects.get_or_create(
                    domain=university_domain,
                    defaults={
                        'university_name': university_name,
                        'submitted_by': user,
                        'status': 'pending'
                    }
                )
                user.is_verified = False
                user.save(update_fields=['is_verified'])

            student_profile = StudentProfile.objects.create(user=user, **validated_data)
            
            if areas_of_expertise:
                student_profile.areas_of_expertise.set(areas_of_expertise)
            
            return student_profile

class StudentProfileUpdateSerializer(serializers.ModelSerializer):
    user = UserSerializer(partial=True)
    areas_of_expertise = serializers.PrimaryKeyRelatedField(
        queryset=ChallengeCategory.objects.all(),
        many=True,
        required=False,
        allow_empty=True
    )

    class Meta:
        model = StudentProfile
        fields = ['user', 'university_name', 'graduation_year', 'skills', 'areas_of_expertise', 'profile_image']
        extra_kwargs = {
            'university_name': {'required': False},
            'graduation_year': {'required': False},
            'skills': {'required': False, 'allow_blank': True},
            'profile_image': {'required': False},
        }

    def to_internal_value(self, data):
        print(f"Raw request data: {data}")  # Debug log
        areas_of_expertise = []
        
        # Extract areas_of_expertise[i] from multipart form data
        i = 0
        while f'areas_of_expertise[{i}]' in data:
            value = data.get(f'areas_of_expertise[{i}]')
            if value:  # Ensure value is not empty
                areas_of_expertise.append(value)
            i += 1
        # Handle empty areas_of_expertise
        if 'areas_of_expertise[]' in data:
            areas_of_expertise = []
        
        # Convert to list of integers and validate
        try:
            areas_of_expertise = [int(id) for id in areas_of_expertise if id]
        except ValueError:
            raise serializers.ValidationError({"areas_of_expertise": "Invalid category IDs"})

        print(f"Processed areas_of_expertise: {areas_of_expertise}")  # Debug log

        # Call super().to_internal_value with the original QueryDict
        validated_data = super().to_internal_value(data)
        
        # Override the areas_of_expertise in validated_data with our processed list
        validated_data['areas_of_expertise'] = areas_of_expertise

        return validated_data

    def update(self, instance, validated_data):
        print(f"Updating StudentProfile with validated_data: {validated_data}")  # Debug log
        with transaction.atomic():
            user_data = validated_data.pop('user', {})
            areas_of_expertise = validated_data.pop('areas_of_expertise', [])
            
            if user_data:
                user_serializer = UserSerializer(instance=instance.user, data=user_data, partial=True, context=self.context)
                if user_serializer.is_valid(raise_exception=True):
                    user_serializer.save()
            
            instance = super().update(instance, validated_data)
            
            print(f"Setting areas_of_expertise to: {areas_of_expertise}")  # Debug log
            instance.areas_of_expertise.set(areas_of_expertise)
            
            return instance

class GraduateProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    university_domain = serializers.CharField(write_only=True, required=False, allow_blank=True)
    areas_of_expertise = serializers.PrimaryKeyRelatedField(
        queryset=ChallengeCategory.objects.all(),
        many=True,
        required=False,
        allow_empty=True
    )

    class Meta:
        model = GraduateProfile
        fields = ['user', 'university_name', 'university_domain', 'graduation_year', 'current_position', 'skills', 'areas_of_expertise']

    def create(self, validated_data):
        with transaction.atomic():
            user_data = validated_data.pop('user')
            university_domain = validated_data.pop('university_domain', '').lower()
            university_name = validated_data['university_name']
            areas_of_expertise = validated_data.pop('areas_of_expertise', [])

            user = UserSerializer().create(user_data)

            if university_domain:
                try:
                    university = University.objects.get(domain=university_domain, is_verified=True)
                    user.is_verified = True
                    user.save(update_fields=['is_verified'])
                except University.DoesNotExist:
                    PendingSchoolDomain.objects.get_or_create(
                        domain=university_domain,
                        defaults={
                            'university_name': university_name,
                            'submitted_by': user,
                            'status': 'pending'
                        }
                    )

            graduate_profile = GraduateProfile.objects.create(user=user, **validated_data)
            
            if areas_of_expertise:
                graduate_profile.areas_of_expertise.set(areas_of_expertise)
            
            return graduate_profile

class GraduateProfileUpdateSerializer(serializers.ModelSerializer):
    user = UserSerializer(partial=True)
    areas_of_expertise = serializers.PrimaryKeyRelatedField(
        queryset=ChallengeCategory.objects.all(),
        many=True,
        required=False,
        allow_empty=True
    )

    class Meta:
        model = GraduateProfile
        fields = ['user', 'university_name', 'graduation_year', 'current_position', 'skills', 'areas_of_expertise', 'profile_image']
        extra_kwargs = {
            'university_name': {'required': False},
            'graduation_year': {'required': False},
            'current_position': {'required': False, 'allow_blank': True},
            'skills': {'required': False, 'allow_blank': True},
            'profile_image': {'required': False},
        }

    def to_internal_value(self, data):
        print(f"Raw request data: {data}")  # Debug log
        areas_of_expertise = []
        
        # Extract areas_of_expertise[i] from multipart form data
        i = 0
        while f'areas_of_expertise[{i}]' in data:
            value = data.get(f'areas_of_expertise[{i}]')
            if value:  # Ensure value is not empty
                areas_of_expertise.append(value)
            i += 1
        # Handle empty areas_of_expertise
        if 'areas_of_expertise[]' in data:
            areas_of_expertise = []
        
        # Convert to list of integers and validate
        try:
            areas_of_expertise = [int(id) for id in areas_of_expertise if id]
        except ValueError:
            raise serializers.ValidationError({"areas_of_expertise": "Invalid category IDs"})

        print(f"Processed areas_of_expertise: {areas_of_expertise}")  # Debug log

        # Call super().to_internal_value with the original QueryDict
        validated_data = super().to_internal_value(data)
        
        # Override the areas_of_expertise in validated_data with our processed list
        validated_data['areas_of_expertise'] = areas_of_expertise

        return validated_data

    def update(self, instance, validated_data):
        print(f"Updating GraduateProfile with validated_data: {validated_data}")  # Debug log
        with transaction.atomic():
            user_data = validated_data.pop('user', {})
            areas_of_expertise = validated_data.pop('areas_of_expertise', [])
            
            if user_data:
                user_serializer = UserSerializer(instance=instance.user, data=user_data, partial=True, context=self.context)
                if user_serializer.is_valid(raise_exception=True):
                    user_serializer.save()
            
            instance = super().update(instance, validated_data)
            
            print(f"Setting areas_of_expertise to: {areas_of_expertise}")  # Debug log
            instance.areas_of_expertise.set(areas_of_expertise)
            
            return instance

class CompanyProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    company_domain = serializers.CharField(write_only=True)
    website = serializers.URLField(required=False, allow_blank=True)

    class Meta:
        model = CompanyProfile
        fields = ['user', 'company_name', 'company_domain', 'industry', 'website', 'verification_status']

    def create(self, validated_data):
        with transaction.atomic():
            user_data = validated_data.pop('user')
            company_domain = validated_data.pop('company_domain').lower()
            website = validated_data.get('website', '')
            
            user = UserSerializer().create(user_data)
            company_profile = CompanyProfile.objects.create(user=user, **validated_data)
            
            PendingCompanyDomain.objects.create(
                domain=company_domain,
                company_name=validated_data['company_name'],
                industry=validated_data['industry'],
                website=website,
                submitted_by=user
            )
            return company_profile

class MentorProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()

    class Meta:
        model = MentorProfile
        fields = ['user', 'expertise_areas', 'bio', 'availability']

    def create(self, validated_data):
        with transaction.atomic():
            user_data = validated_data.pop('user')
            user = UserSerializer().create(user_data)
            mentor_profile = MentorProfile.objects.create(user=user, **validated_data)
            return mentor_profile

class AdminProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()

    class Meta:
        model = AdminProfile
        fields = ['user']

    def create(self, validated_data):
        with transaction.atomic():
            user_data = validated_data.pop('user')
            user = UserSerializer().create(user_data)
            admin_profile = AdminProfile.objects.create(user=user)
            return admin_profile

class PendingSchoolDomainSerializer(serializers.ModelSerializer):
    class Meta:
        model = PendingSchoolDomain
        fields = ['id', 'domain', 'university_name', 'submitted_by', 'status', 'created_at']

class PendingCompanyDomainSerializer(serializers.ModelSerializer):
    class Meta:
        model = PendingCompanyDomain
        fields = ['id', 'domain', 'company_name', 'industry', 'website', 'submitted_by', 'status', 'created_at']

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        email = data.get('email')
        password = data.get('password')

        user = authenticate(email=email, password=password)
        if not user:
            raise serializers.ValidationError({"error": "Invalid credentials"})

        if user.role == 'student':
            if not user.is_verified:
                raise serializers.ValidationError({"error": "Account pending verification"})
            if not StudentEnrollment.objects.filter(
                student=user,
                university__is_verified=True
            ).exists():
                raise serializers.ValidationError({"error": "No active enrollment in a verified university"})
        elif user.role == 'company_user':
            if not user.is_verified:
                raise serializers.ValidationError({"error": "Account pending verification"})
        data['user'] = user
        return data