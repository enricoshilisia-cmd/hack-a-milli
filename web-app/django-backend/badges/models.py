# badges/models.py
from django.db import models
from users.models import CustomUser
from submissions.models import Submission

class Badge(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField()
    icon = models.ImageField(upload_to='badges/', blank=True)
    criteria = models.TextField()  # e.g., "Score > 80 on challenge X"

    def __str__(self):
        return self.name

class UserBadge(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE)
    earned_at = models.DateTimeField(auto_now_add=True)
    evidence = models.ForeignKey(Submission, on_delete=models.SET_NULL, null=True)

    class Meta:
        unique_together = ('user', 'badge')

    def __str__(self):
        return f"{self.badge.name} earned by {self.user.email}"