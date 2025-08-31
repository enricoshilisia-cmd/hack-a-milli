from django.db import models
from companies.models import Company
from users.models import CustomUser

class ChallengeCategory(models.Model):
    name = models.CharField(max_length=100, unique=True, db_index=True)  # e.g., "Developers", "HR", "Sales", "Accounting"
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)

    def __str__(self):
        return self.name

    class Meta:
        indexes = [
            models.Index(fields=['name']),
        ]

class Challenge(models.Model):
    DIFFICULTY_CHOICES = (
        ('beginner', 'Beginner'),
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
        ('expert', 'Expert'),
    )
    TYPE_CHOICES = (
        ('coding', 'Coding'),  # Programming tasks (e.g., algorithms, web development)
        ('design', 'Design'),  # UI/UX, graphic design
        ('document', 'Document'),  # Reports, proposals
        ('data_analysis', 'Data Analysis'),  # Data cleaning, visualization, ML
        ('case_study', 'Case Study'),  # Business or technical problem-solving
        ('presentation', 'Presentation'),  # Slide decks, pitches
        ('quiz', 'Quiz'),  # Multiple-choice or short-answer tests
        ('simulation', 'Simulation'),  # Role-based scenarios (e.g., sales pitch, HR interview)
        ('creative_writing', 'Creative Writing'),  # Storytelling, copywriting
        ('project_management', 'Project Management'),  # Planning, scheduling
        ('financial_analysis', 'Financial Analysis'),  # Budgeting, forecasting
        ('marketing_campaign', 'Marketing Campaign'),  # Ad campaigns, social media plans
        ('sales_pitch', 'Sales Pitch'),  # Pitching a product or service
        ('hr_strategy', 'HR Strategy'),  # Recruitment plans, employee engagement
        ('research', 'Research'),  # Literature reviews, market research
        ('video_production', 'Video Production'),  # Video editing, storytelling
        ('consulting', 'Consulting'),  # Strategy development
        ('product_design', 'Product Design'),  # Product ideation, prototyping
        ('other', 'Other'),  # Custom or miscellaneous challenges
    )
    VISIBILITY_CHOICES = (
        ('public', 'Public'),  # Global access
        ('company', 'Company-Specific'),  # Only for company users
        ('group', 'Group-Specific'),  # Specific role-based group
    )
    SUBMISSION_FORMAT_CHOICES = (
        ('file', 'File Upload'),  # PDFs, code files, etc.
        ('url', 'URL Link'),  # GitHub, portfolio links
        ('text', 'Text Input'),  # Written responses
        ('video', 'Video Submission'),  # Video pitches
        ('multiple', 'Multiple Formats'),  # Combination of above
    )

    title = models.CharField(max_length=255, db_index=True)
    description = models.TextField()
    challenge_type = models.CharField(max_length=50, choices=TYPE_CHOICES, db_index=True)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, db_index=True)
    visibility = models.CharField(max_length=20, choices=VISIBILITY_CHOICES, default='public', db_index=True)
    company = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True, db_index=True)
    categories = models.ManyToManyField(ChallengeCategory, related_name='challenges')  # Support multiple roles (e.g., Developers, HR)
    created_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, related_name='created_challenges', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    start_date = models.DateTimeField(null=True, blank=True, db_index=True)
    end_date = models.DateTimeField(null=True, blank=True, db_index=True)
    duration_minutes = models.IntegerField(null=True, blank=True)
    max_submissions = models.IntegerField(default=1)
    is_collaborative = models.BooleanField(default=False)
    max_team_size = models.IntegerField(null=True, blank=True)
    skill_tags = models.TextField(blank=True)
    learning_outcomes = models.TextField(blank=True)
    prerequisite_description = models.TextField(blank=True)
    estimated_completion_time = models.IntegerField(null=True, blank=True)
    max_score = models.FloatField(default=100.0)
    is_published = models.BooleanField(default=False, db_index=True)
    is_featured = models.BooleanField(default=False, help_text="Mark as featured for dashboard carousel", null=True, blank=True, db_index=True)
    thumbnail = models.ImageField(upload_to='challenges/thumbnails/', blank=True, null=True, help_text="Thumbnail image for the challenge")

    def __str__(self):
        return self.title

    class Meta:
        indexes = [
            models.Index(fields=['is_published', 'visibility']),
            models.Index(fields=['company', 'created_by']),
        ]

class Task(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='tasks', db_index=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    order = models.IntegerField(default=1, db_index=True)
    max_score = models.FloatField(null=True, blank=True)
    expected_output = models.TextField(blank=True)
    test_cases = models.TextField(blank=True)
    time_limit_minutes = models.IntegerField(null=True, blank=True)
    is_mandatory = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.title} in {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['challenge', 'order']),
        ]

class ChallengeAttachment(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='attachments', db_index=True)
    file = models.FileField(upload_to='challenge_attachments/')
    description = models.CharField(max_length=255, blank=True)
    is_required = models.BooleanField(default=False)

    def __str__(self):
        return f"Attachment for {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['challenge', 'is_required']),
        ]

class ChallengePrerequisite(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='prerequisites', db_index=True)
    prerequisite_challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='dependent_challenges', db_index=True)
    required_score = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"Prerequisite {self.prerequisite_challenge.title} for {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['challenge', 'prerequisite_challenge']),
        ]

class ChallengeRubric(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='rubrics', db_index=True)
    criterion = models.CharField(max_length=255, db_index=True)
    description = models.TextField()
    max_score = models.FloatField()
    weight = models.FloatField(default=1.0)

    def __str__(self):
        return f"{self.criterion} for {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['challenge', 'criterion']),
        ]

class ChallengeGroup(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='groups', db_index=True)
    name = models.CharField(max_length=100, db_index=True)
    description = models.TextField(blank=True)
    is_role_based = models.BooleanField(default=True, db_index=True)

    def __str__(self):
        return f"{self.name} for {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['challenge', 'is_role_based']),
        ]

class ChallengeFeedback(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='feedback', db_index=True)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, db_index=True)
    comment = models.TextField()
    rating = models.IntegerField(null=True, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Feedback by {self.user.email} for {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['challenge', 'user']),
            models.Index(fields=['rating']),
        ]