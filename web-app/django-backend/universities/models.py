from django.db import models

class University(models.Model):
    name = models.CharField(max_length=255, unique=True)
    location = models.CharField(max_length=100, default='Unknown')
    domain = models.CharField(max_length=255, unique=True)
    is_verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name_plural = "Universities"

class UniversityUser(models.Model):
    university = models.ForeignKey(University, on_delete=models.CASCADE)
    user = models.ForeignKey('users.CustomUser', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.email} at {self.university.name}"

class StudentEnrollment(models.Model):
    student = models.ForeignKey('users.CustomUser', on_delete=models.CASCADE)
    university = models.ForeignKey(University, on_delete=models.PROTECT)
    enrollment_date = models.DateField(default='2025-01-01')
    graduation_date = models.DateField(null=True, blank=True)

    class Meta:
        unique_together = ('student', 'university')

    def __str__(self):
        return f"{self.student.email} enrolled at {self.university.name}"