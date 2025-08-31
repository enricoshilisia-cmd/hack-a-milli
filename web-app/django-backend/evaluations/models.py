# evaluations/models.py
from django.db import models
from submissions.models import Submission

class EvaluationRubric(models.Model):
    challenge = models.ForeignKey('challenges.Challenge', on_delete=models.CASCADE)
    criteria = models.JSONField()  # e.g., {"correctness": 40, "completeness": 30}
    description = models.TextField(blank=True)

    def __str__(self):
        return f"Rubric for {self.challenge.title}"

class Evaluation(models.Model):
    submission = models.OneToOneField(Submission, on_delete=models.CASCADE)
    auto_score = models.FloatField(null=True, blank=True)
    rubric_breakdown = models.JSONField(null=True, blank=True)
    ai_feedback = models.TextField(blank=True)
    human_override = models.BooleanField(default=False)
    final_score = models.FloatField(null=True, blank=True)
    evaluated_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Evaluation for submission {self.submission.id}"

class EvaluationLog(models.Model):
    evaluation = models.ForeignKey(Evaluation, on_delete=models.CASCADE)
    step = models.CharField(max_length=100)  # e.g., "plagiarism_check", "sandbox_run"
    result = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Log for evaluation {self.evaluation.id} - {self.step}"