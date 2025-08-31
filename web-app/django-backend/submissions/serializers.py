from rest_framework import serializers
from .models import Submission, SubmissionFile, SubmissionReview
from challenges.serializers import ChallengeSerializer, StudentChallengeSerializer
from users.models import CustomUser
import logging

# Set up logging
logger = logging.getLogger(__name__)

class SubmissionFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubmissionFile
        fields = ['id', 'file', 'submission']

class SubmissionReviewSerializer(serializers.ModelSerializer):
    reviewer = serializers.PrimaryKeyRelatedField(read_only=True)
    submission = serializers.PrimaryKeyRelatedField(read_only=True)  # Make submission read_only

    class Meta:
        model = SubmissionReview
        fields = ['id', 'submission', 'reviewer', 'comments', 'score', 'reviewed_at']

    def validate_score(self, value):
        submission = self.context.get('submission')
        if not submission:
            logger.error("Submission context not provided for score validation")
            raise serializers.ValidationError("Submission context is required for score validation")
        if not isinstance(value, (int, float)):
            logger.error(f"Invalid score type: {type(value)}, value: {value}")
            raise serializers.ValidationError("Score must be a number")
        if value < 0 or value > submission.challenge.max_score:
            logger.error(f"Score out of range: {value}, max_score: {submission.challenge.max_score}")
            raise serializers.ValidationError(f"Score must be between 0 and {submission.challenge.max_score}")
        return value

class SubmissionSerializer(serializers.ModelSerializer):
    challenge = ChallengeSerializer(read_only=True)
    user = serializers.PrimaryKeyRelatedField(read_only=True)
    files = SubmissionFileSerializer(many=True, read_only=True)
    reviews = SubmissionReviewSerializer(many=True, read_only=True)

    class Meta:
        model = Submission
        fields = ['id', 'user', 'challenge', 'repo_link', 'submitted_at', 'status', 'files', 'reviews']

    def validate(self, data):
        if not data.get('repo_link'):
            raise serializers.ValidationError({"repo_link": "This field is required."})
        return data

    def create(self, validated_data):
        files_data = self.context['request'].FILES.getlist('files', [])
        submission = Submission.objects.create(**validated_data)
        for file_data in files_data:
            SubmissionFile.objects.create(submission=submission, file=file_data)
        return submission

class StudentSubmissionSerializer(serializers.ModelSerializer):
    challenge = StudentChallengeSerializer(read_only=True)
    files = SubmissionFileSerializer(many=True, read_only=True)
    reviews = SubmissionReviewSerializer(many=True, read_only=True)
    challenge_title = serializers.CharField(source='challenge.title', read_only=True)
    score = serializers.SerializerMethodField()

    class Meta:
        model = Submission
        fields = ['id', 'challenge', 'challenge_title', 'repo_link', 'submitted_at', 'status', 'files', 'reviews', 'score']

    def get_score(self, obj):
        review = obj.reviews.first()
        return review.score if review else None

class ParticipantSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'email']

class StudentChallengeResultsSerializer(serializers.ModelSerializer):
    challenge_title = serializers.CharField(source='challenge.title', read_only=True)
    score = serializers.SerializerMethodField()

    class Meta:
        model = Submission
        fields = ['challenge_title', 'score']

    def get_score(self, obj):
        review = obj.reviews.first()
        return review.score if review else None

class StudentPendingAndRejectedSerializer(serializers.ModelSerializer):
    challenge_title = serializers.CharField(source='challenge.title', read_only=True)
    status = serializers.CharField(read_only=True)

    class Meta:
        model = Submission
        fields = ['challenge_title', 'status']