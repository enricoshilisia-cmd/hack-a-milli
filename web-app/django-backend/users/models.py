from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

from users.utils import validate_user_domain

class CustomUserManager(BaseUserManager):
    def _create_user(self, email, password, **extra_fields):
        """
        Create and save a user with the given email and password.
        """
        if not email:
            raise ValueError('The Email must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save()
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_verified', True)
        extra_fields.setdefault('role', 'admin')

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self._create_user(email, password, **extra_fields)

class CustomUser(AbstractUser):
    ROLE_CHOICES = (
        ('student', 'Student'),
        ('graduate', 'Graduate'),
        ('company_user', 'Company User'),
        ('mentor', 'Mentor'),
        ('admin', 'Admin'),
    )
    
    username = models.CharField(max_length=150, null=True, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, db_index=True)
    email = models.EmailField(unique=True, db_index=True)
    is_verified = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    phone_number = models.CharField(max_length=15, blank=True, null=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['role']

    objects = CustomUserManager()

    class Meta:
        indexes = [
            models.Index(fields=['role', 'is_verified']),
        ]

    def clean(self):
        super().clean()
        validate_user_domain(self)

    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        if not self.username:
            self.username = None
        super().save(*args, **kwargs)

class StudentProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='student_profile', db_index=True)
    university_name = models.CharField(max_length=255)
    graduation_year = models.IntegerField(null=True, blank=True, db_index=True)
    skills = models.TextField(blank=True)
    areas_of_expertise = models.ManyToManyField(
        'challenges.ChallengeCategory', 
        related_name='students',
        blank=True,
        help_text="Select areas that match your skills and interests"
    )
    profile_image = models.ImageField(upload_to='profile_images/', blank=True, null=True)
    
    def __str__(self):
        return f"Profile for {self.user.email}"

    class Meta:
        indexes = [
            models.Index(fields=['university_name']),
        ]

class GraduateProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='graduate_profile', db_index=True)
    university_name = models.CharField(max_length=255)
    graduation_year = models.IntegerField(db_index=True)
    current_position = models.CharField(max_length=255, blank=True)
    skills = models.TextField(blank=True)
    areas_of_expertise = models.ManyToManyField(
        'challenges.ChallengeCategory', 
        related_name='graduates',
        blank=True,
        help_text="Select areas that match your professional expertise"
    )
    profile_image = models.ImageField(upload_to='profile_images/', blank=True, null=True)
    
    def __str__(self):
        return f"Profile for {self.user.email}"

    class Meta:
        indexes = [
            models.Index(fields=['university_name', 'graduation_year']),
        ]

class CompanyProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='company_profile', db_index=True)
    company_name = models.CharField(max_length=255, db_index=True)
    industry = models.CharField(max_length=100, db_index=True)
    verification_status = models.CharField(max_length=20, default='pending', db_index=True)
    website = models.URLField(blank=True)

    def __str__(self):
        return f"Profile for {self.user.email}"

    class Meta:
        indexes = [
            models.Index(fields=['company_name', 'industry']),
        ]

class MentorProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='mentor_profile', db_index=True)
    expertise_areas = models.TextField()
    bio = models.TextField(blank=True)
    availability = models.CharField(max_length=100, blank=True, db_index=True)

    def __str__(self):
        return f"Profile for {self.user.email}"

    class Meta:
        indexes = [
            models.Index(fields=['availability']),
        ]

class AdminProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='admin_profile', db_index=True)

    def __str__(self):
        return f"Profile for {self.user.email}"

class PendingSchoolDomain(models.Model):
    domain = models.CharField(max_length=255, unique=True, db_index=True)
    university_name = models.CharField(max_length=255)
    submitted_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, db_index=True)
    status = models.CharField(max_length=20, default='pending', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.domain} ({self.status})"

    class Meta:
        indexes = [
            models.Index(fields=['university_name', 'status']),
        ]

class PendingCompanyDomain(models.Model):
    domain = models.CharField(max_length=255, unique=True, db_index=True)
    company_name = models.CharField(max_length=255)
    industry = models.CharField(max_length=100, db_index=True)
    website = models.URLField(blank=True)
    submitted_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, db_index=True)
    status = models.CharField(max_length=20, default='pending', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.domain} ({self.status})"

    class Meta:
        indexes = [
            models.Index(fields=['company_name', 'industry', 'status']),
        ]