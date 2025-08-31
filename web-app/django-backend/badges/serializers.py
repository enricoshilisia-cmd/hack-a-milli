from rest_framework import serializers
from .models import Badge, UserBadge
from users.models import CustomUser
from submissions.models import Submission

class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = ['id', 'name', 'description', 'icon', 'criteria']

class UserBadgeSerializer(serializers.ModelSerializer):
    badge = BadgeSerializer(read_only=True)
    user = serializers.PrimaryKeyRelatedField(read_only=True)
    evidence = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = UserBadge
        fields = ['id', 'user', 'badge', 'earned_at', 'evidence']