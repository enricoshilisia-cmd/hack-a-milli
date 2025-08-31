from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from universities.models import University

def validate_user_domain(user):
    if user.is_verified and user.role in ['student', 'company_user']:  # Notice graduate is not here
        domain = user.email.split('@')[-1].lower()
        
        if user.role == 'student':
            if not University.objects.filter(domain=domain, is_verified=True).exists():
                raise ValidationError(_('Student email must use a verified university domain.'))
        
        elif user.role == 'company_user':
            from companies.models import Company
            if not Company.objects.filter(domain=domain, verified=True).exists():
                raise ValidationError(_('Company user email must use a verified company domain.'))