from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _
from django.db import transaction
from .models import (
    CustomUser,
    StudentProfile,
    CompanyProfile,
    MentorProfile,
    AdminProfile,
    PendingSchoolDomain,
    PendingCompanyDomain
)
from universities.models import University, StudentEnrollment

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ('email', 'role', 'is_verified', 'is_staff', 'is_superuser')
    list_filter = ('role', 'is_verified', 'is_staff', 'is_superuser')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'role')}),
        (_('Permissions'), {
            'fields': ('is_verified', 'is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {'fields': ('last_login', 'created_at', 'updated_at')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'role', 'password1', 'password2'),
        }),
    )
    
    readonly_fields = ('created_at', 'updated_at')

class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'university_name', 'graduation_year')
    list_filter = ('university_name', 'graduation_year')
    search_fields = ('user__email', 'university_name', 'skills')
    raw_id_fields = ('user',)
    
    fieldsets = (
        (None, {'fields': ('user',)}),
        (_('Education'), {'fields': ('university_name', 'graduation_year')}),
        (_('Skills'), {'fields': ('skills',)}),
    )

class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'company_name', 'industry', 'verification_status')
    list_filter = ('industry', 'verification_status')
    search_fields = ('user__email', 'company_name', 'website')
    raw_id_fields = ('user',)
    
    fieldsets = (
        (None, {'fields': ('user',)}),
        (_('Company Info'), {'fields': ('company_name', 'industry', 'website')}),
        (_('Verification'), {'fields': ('verification_status',)}),
    )

class MentorProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'expertise_areas')
    search_fields = ('user__email', 'expertise_areas', 'bio')
    raw_id_fields = ('user',)
    
    fieldsets = (
        (None, {'fields': ('user',)}),
        (_('Expertise'), {'fields': ('expertise_areas',)}),
        (_('Profile'), {'fields': ('bio', 'availability')}),
    )

class AdminProfileAdmin(admin.ModelAdmin):
    list_display = ('user',)
    search_fields = ('user__email',)
    raw_id_fields = ('user',)

class PendingSchoolDomainAdmin(admin.ModelAdmin):
    list_display = ('domain', 'university_name', 'submitted_by', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('domain', 'university_name', 'submitted_by__email')
    raw_id_fields = ('submitted_by',)
    actions = ['approve_domains']
    
    def approve_domains(self, request, queryset):
        """Approve selected pending school domains and verify associated students."""
        from django.utils import timezone
        
        updated_count = 0
        with transaction.atomic():
            for domain in queryset.filter(status='pending'):
                # Create or get university
                university, created = University.objects.get_or_create(
                    domain=domain.domain,
                    defaults={
                        'name': domain.university_name,
                        'location': 'Unknown',
                        'is_verified': True,
                        'verified_at': timezone.now()
                    }
                )
                if not created and not university.is_verified:
                    university.is_verified = True
                    university.verified_at = timezone.now()
                    university.save()
                
                # Verify submitting user if not already verified
                if not domain.submitted_by.is_verified:
                    domain.submitted_by.is_verified = True
                    domain.submitted_by.save(update_fields=['is_verified'])
                
                # Create enrollment for submitting user if it doesn't exist
                StudentEnrollment.objects.get_or_create(
                    student=domain.submitted_by,
                    university=university,
                    defaults={'enrollment_date': '2025-01-01'}
                )
                
                # Verify all unverified students with this domain
                domain_part = f"@{domain.domain}"
                students = CustomUser.objects.filter(
                    email__endswith=domain_part,
                    role='student',
                    is_verified=False
                )
                verified_count = students.update(is_verified=True)
                
                # Update domain status
                domain.status = 'approved'
                domain.save()
                
                updated_count += 1
                
            self.message_user(request, f"Approved {updated_count} domains and verified {verified_count} students")

    approve_domains.short_description = "Approve selected domains"

class PendingCompanyDomainAdmin(admin.ModelAdmin):
    list_display = ('domain', 'company_name', 'industry', 'submitted_by', 'status', 'created_at')
    list_filter = ('status', 'industry', 'created_at')
    search_fields = ('domain', 'company_name', 'submitted_by__email', 'website')
    raw_id_fields = ('submitted_by',)
    actions = ['approve_domains']
    
    def approve_domains(self, request, queryset):
        """Mark selected company domains as approved."""
        from companies.models import Company, CompanyUser
        from django.utils import timezone
        
        updated_count = 0
        with transaction.atomic():
            for domain in queryset.filter(status='pending'):
                # Create company
                company = Company.objects.create(
                    name=domain.company_name,
                    industry=domain.industry,
                    website=domain.website,
                    domain=domain.domain,
                    verified=True
                )
                
                # Verify submitting user
                if not domain.submitted_by.is_verified:
                    domain.submitted_by.is_verified = True
                    domain.submitted_by.save(update_fields=['is_verified'])
                
                # Create company user relationship
                CompanyUser.objects.create(
                    company=company,
                    user=domain.submitted_by,
                    role_in_company='recruiter'
                )
                
                # Update company profile verification status
                company_profile = domain.submitted_by.company_profile
                company_profile.verification_status = 'verified'
                company_profile.save()
                
                # Update domain status
                domain.status = 'approved'
                domain.save()
                
                updated_count += 1
                
            self.message_user(request, f"Approved {updated_count} company domains")
    
    approve_domains.short_description = "Mark selected domains as approved"

admin.site.register(CustomUser, CustomUserAdmin)
admin.site.register(StudentProfile, StudentProfileAdmin)
admin.site.register(CompanyProfile, CompanyProfileAdmin)
admin.site.register(MentorProfile, MentorProfileAdmin)
admin.site.register(AdminProfile, AdminProfileAdmin)
admin.site.register(PendingSchoolDomain, PendingSchoolDomainAdmin)
admin.site.register(PendingCompanyDomain, PendingCompanyDomainAdmin)