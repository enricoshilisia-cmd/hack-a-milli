# recruiters/models.py
from django.db import models
from users.models import CustomUser

class CandidateSearchHistory(models.Model):
    recruiter = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    query = models.TextField()  # JSON of filters, e.g., {"badge": "Python", "score_gt": 80}
    searched_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Search by {self.recruiter.email}"

class Shortlist(models.Model):
    recruiter = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='shortlists')
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class ShortlistCandidate(models.Model):
    shortlist = models.ForeignKey(Shortlist, on_delete=models.CASCADE)
    candidate = models.ForeignKey(CustomUser, on_delete=models.CASCADE)

    class Meta:
        unique_together = ('shortlist', 'candidate')

class ContactRequest(models.Model):
    recruiter = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='sent_requests')
    candidate = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='received_requests')
    message = models.TextField()
    status = models.CharField(max_length=20, default='pending')  # pending/accepted/rejected
    requested_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Request from {self.recruiter.email} to {self.candidate.email}"