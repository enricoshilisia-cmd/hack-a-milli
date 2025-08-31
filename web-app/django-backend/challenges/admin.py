from django.contrib import admin
from .models import (
    ChallengeCategory,
    Challenge,
    Task,
    ChallengeAttachment,
    ChallengePrerequisite,
    ChallengeRubric,
    ChallengeGroup,
    ChallengeFeedback,
)

class TaskInline(admin.TabularInline):
    model = Task
    extra = 1

class ChallengeAttachmentInline(admin.TabularInline):
    model = ChallengeAttachment
    extra = 1

class ChallengePrerequisiteInline(admin.TabularInline):
    model = ChallengePrerequisite
    fk_name = 'challenge'
    extra = 1

class ChallengeRubricInline(admin.TabularInline):
    model = ChallengeRubric
    extra = 1

class ChallengeGroupInline(admin.TabularInline):
    model = ChallengeGroup
    extra = 1

@admin.register(ChallengeCategory)
class ChallengeCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name',)

@admin.register(Challenge)
class ChallengeAdmin(admin.ModelAdmin):
    list_display = ('title', 'challenge_type', 'difficulty', 'visibility', 'is_published', 'is_featured', 'thumbnail')
    list_filter = ('challenge_type', 'difficulty', 'visibility', 'is_published', 'is_featured')
    search_fields = ('title', 'description')
    filter_horizontal = ('categories',)
    inlines = [
        TaskInline,
        ChallengeAttachmentInline,
        ChallengePrerequisiteInline,
        ChallengeRubricInline,
        ChallengeGroupInline,
    ]
    readonly_fields = ('created_at', 'updated_at')
    fields = [
        'title', 'description', 'challenge_type', 'difficulty', 'visibility',
        'company', 'categories', 'created_by', 'start_date', 'end_date',
        'duration_minutes', 'max_submissions', 'is_collaborative', 'max_team_size',
        'skill_tags', 'learning_outcomes', 'prerequisite_description',
        'estimated_completion_time', 'max_score', 'is_published', 'is_featured',
        'thumbnail'
    ]

    def delete_model(self, request, obj):
        """Override to prevent deleting related ChallengeCategory objects."""
        # Only delete the Challenge and its ManyToMany relationships
        obj.categories.clear()  # Remove relationships from join table
        obj.delete()

    def delete_queryset(self, request, queryset):
        """Override to prevent deleting related ChallengeCategory objects."""
        for obj in queryset:
            obj.categories.clear()  # Remove relationships from join table
            obj.delete()

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'challenge', 'order', 'max_score')
    list_filter = ('challenge',)
    search_fields = ('title', 'description')

@admin.register(ChallengeAttachment)
class ChallengeAttachmentAdmin(admin.ModelAdmin):
    list_display = ('challenge', 'file', 'is_required')
    list_filter = ('is_required',)
    search_fields = ('challenge__title', 'description')

@admin.register(ChallengePrerequisite)
class ChallengePrerequisiteAdmin(admin.ModelAdmin):
    list_display = ('challenge', 'prerequisite_challenge', 'required_score')
    search_fields = ('challenge__title', 'prerequisite_challenge__title')

@admin.register(ChallengeRubric)
class ChallengeRubricAdmin(admin.ModelAdmin):
    list_display = ('challenge', 'criterion', 'max_score', 'weight')
    search_fields = ('challenge__title', 'criterion')

@admin.register(ChallengeGroup)
class ChallengeGroupAdmin(admin.ModelAdmin):
    list_display = ('challenge', 'name', 'is_role_based')
    list_filter = ('is_role_based',)
    search_fields = ('challenge__title', 'name')

@admin.register(ChallengeFeedback)
class ChallengeFeedbackAdmin(admin.ModelAdmin):
    list_display = ('challenge', 'user', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('challenge__title', 'user__email', 'comment')
    readonly_fields = ('created_at',)