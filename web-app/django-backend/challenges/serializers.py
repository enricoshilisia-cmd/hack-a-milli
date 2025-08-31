from rest_framework import serializers
from django.utils import timezone
from .models import Challenge, ChallengeCategory, Task, ChallengeAttachment, ChallengeRubric, ChallengeGroup, ChallengeFeedback, ChallengePrerequisite
from companies.models import Company
from users.models import CustomUser

class ChallengeCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengeCategory
        fields = ['id', 'name', 'description']

class ChallengeCategoryNameSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengeCategory
        fields = ['name']

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'order', 'max_score', 'expected_output', 'test_cases', 'time_limit_minutes', 'is_mandatory']

class ChallengeAttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengeAttachment
        fields = ['id', 'file', 'description', 'is_required']

class ChallengeRubricSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengeRubric
        fields = ['id', 'criterion', 'description', 'max_score', 'weight']

class ChallengeGroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengeGroup
        fields = ['id', 'name', 'description', 'is_role_based']

class ChallengePrerequisiteSerializer(serializers.ModelSerializer):
    prerequisite_challenge = serializers.PrimaryKeyRelatedField(queryset=Challenge.objects.all())

    class Meta:
        model = ChallengePrerequisite
        fields = ['id', 'prerequisite_challenge', 'required_score']

class ChallengeFeedbackSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=CustomUser.objects.all())

    class Meta:
        model = ChallengeFeedback
        fields = ['id', 'user', 'comment', 'rating', 'created_at']

class ChallengeSerializer(serializers.ModelSerializer):
    categories = ChallengeCategoryNameSerializer(many=True)
    tasks = TaskSerializer(many=True, read_only=True)
    attachments = ChallengeAttachmentSerializer(many=True, read_only=True)
    rubrics = ChallengeRubricSerializer(many=True, read_only=True)
    groups = ChallengeGroupSerializer(many=True, read_only=True)
    prerequisites = ChallengePrerequisiteSerializer(many=True, read_only=True)
    feedback = ChallengeFeedbackSerializer(many=True, read_only=True)
    company = serializers.PrimaryKeyRelatedField(queryset=Company.objects.all(), required=False)
    submission_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Challenge
        fields = [
            'id', 'title', 'description', 'challenge_type', 'difficulty', 'visibility',
            'company', 'categories', 'created_by', 'created_at', 'updated_at',
            'start_date', 'end_date', 'duration_minutes', 'max_submissions',
            'is_collaborative', 'max_team_size', 'skill_tags', 'learning_outcomes',
            'prerequisite_description', 'estimated_completion_time', 'max_score', 'is_published',
            'tasks', 'attachments', 'rubrics', 'groups', 'prerequisites', 'feedback', 'submission_count'
        ]

    def create(self, validated_data):
        categories_data = validated_data.pop('categories')
        challenge = Challenge.objects.create(**validated_data)
        for category_data in categories_data:
            category_name = category_data['name']
            try:
                category = ChallengeCategory.objects.get(name=category_name)
            except ChallengeCategory.DoesNotExist:
                category = ChallengeCategory.objects.create(name=category_name)
            challenge.categories.add(category)
        return challenge

    def update(self, instance, validated_data):
        categories_data = validated_data.pop('categories', None)
        instance = super().update(instance, validated_data)
        if categories_data is not None:
            instance.categories.clear()
            for category_data in categories_data:
                category_name = category_data['name']
                try:
                    category = ChallengeCategory.objects.get(name=category_name)
                except ChallengeCategory.DoesNotExist:
                    category = ChallengeCategory.objects.create(name=category_name)
                instance.categories.add(category)
        return instance

class StudentChallengeSerializer(serializers.ModelSerializer):
    categories = ChallengeCategorySerializer(many=True)
    tasks = TaskSerializer(many=True, read_only=True)
    attachments = ChallengeAttachmentSerializer(many=True, read_only=True)
    rubrics = ChallengeRubricSerializer(many=True, read_only=True)
    groups = ChallengeGroupSerializer(many=True, read_only=True)
    prerequisites = ChallengePrerequisiteSerializer(many=True, read_only=True)
    feedback = ChallengeFeedbackSerializer(many=True, read_only=True)
    countdown = serializers.SerializerMethodField()
    thumbnail = serializers.ImageField(read_only=True)

    class Meta:
        model = Challenge
        fields = [
            'id', 'title', 'description', 'challenge_type', 'difficulty', 'visibility',
            'categories', 'created_at', 'updated_at', 'start_date', 'end_date',
            'duration_minutes', 'max_submissions', 'is_collaborative', 'max_team_size',
            'skill_tags', 'learning_outcomes', 'prerequisite_description', 'estimated_completion_time',
            'max_score', 'is_published', 'tasks', 'attachments', 'rubrics', 'groups',
            'prerequisites', 'feedback', 'countdown', 'thumbnail'
        ]

    def get_countdown(self, obj):
        if obj.end_date:
            time_left = obj.end_date - timezone.now()
            if time_left.total_seconds() > 0:
                return str(time_left)
            return "Expired"
        return None

class FeaturedChallengeSerializer(serializers.ModelSerializer):
    categories = ChallengeCategorySerializer(many=True)
    thumbnail = serializers.ImageField(read_only=True)

    class Meta:
        model = Challenge
        fields = ['id', 'title', 'description', 'challenge_type', 'difficulty', 'categories', 'thumbnail', 'end_date']