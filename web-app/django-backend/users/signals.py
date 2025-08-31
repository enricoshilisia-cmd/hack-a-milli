from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db import transaction
from users.models import CustomUser
from universities.models import University

@receiver(post_save, sender=CustomUser)
def verify_student_if_domain_verified(sender, instance, created, **kwargs):
    """
    Automatically verify a student if their email domain matches a verified university.
    Runs only on user creation to avoid recursive saves.
    """
    if created and instance.role == 'student':
        with transaction.atomic():
            domain = instance.email.split('@')[-1].lower()
            if University.objects.filter(domain=domain, is_verified=True).exists():
                instance.is_verified = True
                instance.save(update_fields=['is_verified'])