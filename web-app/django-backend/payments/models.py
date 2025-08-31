# payments/models.py
from django.db import models
from users.models import CustomUser
from companies.models import Company

class SubscriptionPlan(models.Model):
    name = models.CharField(max_length=100, unique=True)  # e.g., "Basic", "Premium"
    price = models.DecimalField(max_digits=10, decimal_places=2)
    features = models.JSONField()  # List of features

    def __str__(self):
        return self.name

class Subscription(models.Model):
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.CASCADE)
    subscriber = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=True, blank=True)  # For individuals
    company = models.ForeignKey(Company, on_delete=models.CASCADE, null=True, blank=True)  # For companies
    start_date = models.DateField()
    end_date = models.DateField(null=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.plan.name} subscription"

class Transaction(models.Model):
    subscription = models.ForeignKey(Subscription, on_delete=models.SET_NULL, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=50)  # stripe/paypal/etc.
    status = models.CharField(max_length=20, default='completed')
    transacted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Transaction {self.id} for {self.amount}"