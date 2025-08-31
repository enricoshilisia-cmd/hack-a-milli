# portfolio/models.py
from django.db import models
from users.models import CustomUser
from submissions.models import Submission

class Portfolio(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    display_name = models.CharField(max_length=255, blank=True)
    bio = models.TextField(blank=True)
    is_public = models.BooleanField(default=True)

    def __str__(self):
        return f"Portfolio for {self.user.email}"

class PortfolioItem(models.Model):
    portfolio = models.ForeignKey(Portfolio, on_delete=models.CASCADE, related_name='items')
    submission = models.ForeignKey(Submission, on_delete=models.CASCADE)
    description = models.TextField(blank=True)
    order = models.IntegerField(default=1)

    def __str__(self):
        return f"Item {self.submission.challenge.title} in {self.portfolio.user.email}'s portfolio"