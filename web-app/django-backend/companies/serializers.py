from rest_framework import serializers
from .models import Company

class CompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = ['name', 'logo', 'industry', 'website', 'domain', 'verified']
        extra_kwargs = {
            'domain': {'read_only': True},
            'verified': {'read_only': True},
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['logo'] = serializers.ImageField(use_url=True, required=False, allow_null=True)