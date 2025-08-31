from django.db import models
from users.models import CustomUser
from challenges.models import Challenge

class Submission(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('graded', 'Graded'),
        ('rejected', 'Rejected'),
    )
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, db_index=True)
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, db_index=True)
    repo_link = models.URLField(blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True, db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)

    def __str__(self):
        return f"Submission by {self.user.email} for {self.challenge.title}"

    class Meta:
        indexes = [
            models.Index(fields=['user', 'challenge']),
            models.Index(fields=['status', 'submitted_at']),
        ]

class SubmissionFile(models.Model):
    submission = models.ForeignKey(Submission, on_delete=models.CASCADE, related_name='files', db_index=True)
    file = models.FileField(upload_to='submission_files/')

    def __str__(self):
        return f"File for submission {self.submission.id}"

    class Meta:
        indexes = [
            models.Index(fields=['submission']),
        ]

class SubmissionReview(models.Model):
    submission = models.ForeignKey(Submission, on_delete=models.CASCADE, related_name='reviews', db_index=True)
    reviewer = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, db_index=True)
    comments = models.TextField()
    score = models.FloatField()
    reviewed_at = models.DateTimeField(auto_now_add=True, db_index=True)

    def __str__(self):
        return f"Review for submission {self.submission.id}"

    class Meta:
        indexes = [
            models.Index(fields=['submission', 'reviewer']),
            models.Index(fields=['reviewed_at']),
        ]