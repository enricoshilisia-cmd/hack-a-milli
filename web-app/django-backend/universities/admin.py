from django.contrib import admin
from universities.models import University, StudentEnrollment

class UniversityAdmin(admin.ModelAdmin):
    list_display = ('name', 'domain', 'is_verified', 'verified_at')
    list_filter = ('is_verified',)
    search_fields = ('name', 'domain')
    readonly_fields = ('created_at', 'verified_at')
    actions = ['verify_universities']

    def verify_universities(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(is_verified=True, verified_at=timezone.now())
        self.message_user(request, f"Verified {updated} universities")
    verify_universities.short_description = "Verify selected universities"

class StudentEnrollmentAdmin(admin.ModelAdmin):
    list_display = ('student', 'university', 'enrollment_date')
    raw_id_fields = ('student', 'university')

admin.site.register(University, UniversityAdmin)
admin.site.register(StudentEnrollment, StudentEnrollmentAdmin)