# notifications/models.py
from django.db import models
from users.models import CustomUser

class Notification(models.Model):
    TYPE_CHOICES = (
        ('submission_update', 'Submission Update'),
        ('badge_earned', 'Badge Earned'),
        ('contact_request', 'Contact Request'),
        ('other', 'Other'),
    )
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    notification_type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    message = models.TextField()
    related_object_id = models.PositiveIntegerField(null=True, blank=True)  # Generic relation ID
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.email}: {self.message[:50]}"

class DeviceToken(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    token = models.CharField(max_length=255)  # For push notifications
    device_type = models.CharField(max_length=50)  # ios/android/web

    def __str__(self):
        return f"Token for {self.user.email}"