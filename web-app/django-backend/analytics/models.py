# analytics/models.py
from django.db import models
from challenges.models import Challenge
from users.models import CustomUser

class ChallengeAnalytics(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE)
    completions = models.IntegerField(default=0)
    pass_rate = models.FloatField(default=0.0)
    average_score = models.FloatField(default=0.0)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Analytics for {self.challenge.title}"

class UserAnalytics(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    submissions_made = models.IntegerField(default=0)
    average_score = models.FloatField(default=0.0)
    badges_earned = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Analytics for {self.user.email}"