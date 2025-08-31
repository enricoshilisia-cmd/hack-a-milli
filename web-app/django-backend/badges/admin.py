from django.contrib import admin
from .models import Badge, UserBadge
from django.utils.safestring import mark_safe

@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name', 'description', 'criteria')
    readonly_fields = ('icon_preview',)
    
    def icon_preview(self, obj):
        if obj.icon and hasattr(obj.icon, 'url'):
            try:
                return mark_safe(f'<img src="{obj.icon.url}" style="max-height: 100px; max-width: 100px;" />')
            except ValueError:
                return "Icon file not found"
        return "No icon uploaded"

@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ('user', 'badge', 'earned_at')
    list_filter = ('badge', 'earned_at')
    search_fields = ('user__email', 'badge__name')
    readonly_fields = ('earned_at',)
    raw_id_fields = ('user', 'badge', 'evidence')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'badge', 'evidence')