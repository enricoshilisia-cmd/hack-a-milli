from django.contrib import admin
from .models import Submission, SubmissionFile, SubmissionReview

class SubmissionFileInline(admin.TabularInline):
    model = SubmissionFile
    extra = 1

class SubmissionReviewInline(admin.TabularInline):
    model = SubmissionReview
    extra = 1

@admin.register(Submission)
class SubmissionAdmin(admin.ModelAdmin):
    list_display = ('user', 'challenge', 'status', 'submitted_at')
    list_filter = ('status', 'submitted_at', 'challenge')
    search_fields = ('user__email', 'challenge__title')
    inlines = [SubmissionFileInline, SubmissionReviewInline]
    readonly_fields = ('submitted_at',)

@admin.register(SubmissionFile)
class SubmissionFileAdmin(admin.ModelAdmin):
    list_display = ('submission', 'file')
    list_filter = ('submission__status',)
    search_fields = ('submission__user__email', 'submission__challenge__title')

@admin.register(SubmissionReview)
class SubmissionReviewAdmin(admin.ModelAdmin):
    list_display = ('submission', 'reviewer', 'score', 'reviewed_at')
    list_filter = ('reviewed_at', 'score')
    search_fields = ('submission__user__email', 'reviewer__email', 'submission__challenge__title')
    readonly_fields = ('reviewed_at',)