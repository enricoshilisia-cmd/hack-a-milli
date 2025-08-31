from django.db import models

class Company(models.Model):
    name = models.CharField(max_length=255, unique=True)
    logo = models.ImageField(upload_to='company_logos/', blank=True, null=True)
    industry = models.CharField(max_length=100)
    website = models.URLField(blank=True)
    domain = models.CharField(max_length=255, unique=True)
    verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class CompanyUser(models.Model):
    company = models.ForeignKey(Company, on_delete=models.CASCADE)
    user = models.ForeignKey('users.CustomUser', on_delete=models.CASCADE)
    role_in_company = models.CharField(max_length=100, default='recruiter')

    class Meta:
        unique_together = ('company', 'user')

    def __str__(self):
        return f"{self.user.email} at {self.company.name}"

class CompanyPlan(models.Model):
    company = models.ForeignKey(Company, on_delete=models.CASCADE)
    plan_type = models.CharField(max_length=50)
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"{self.plan_type} plan for {self.company.name}"