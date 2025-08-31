# mentors/models.py
from django.db import models
from users.models import CustomUser
from submissions.models import Submission

class MentorAssignment(models.Model):
    mentor = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    submission = models.ForeignKey(Submission, on_delete=models.CASCADE)
    assigned_at = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.mentor.email} assigned to {self.submission.id}"

class MentorSession(models.Model):
    mentor = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='mentor_sessions')
    mentee = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='mentee_sessions')
    session_type = models.CharField(max_length=50)  # chat/video/call
    scheduled_at = models.DateTimeField()
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Session between {self.mentor.email} and {self.mentee.email}"