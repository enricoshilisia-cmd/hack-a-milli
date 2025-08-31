from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import CompanyUser, Company
from .serializers import CompanySerializer

class CompanyProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'company_user':
            return Response({"error": "Only company users can access company profile"}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            company = company_user.company
            serializer = CompanySerializer(company, context={'request': request})
            return Response(serializer.data, status=status.HTTP_200_OK)
        except CompanyUser.DoesNotExist:
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request):
        if request.user.role != 'company_user':
            return Response({"error": "Only company users can update company profile"}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            company_user = CompanyUser.objects.get(user=request.user)
            company = company_user.company
            serializer = CompanySerializer(company, data=request.data, partial=True, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response({"message": "Company profile updated successfully"}, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except CompanyUser.DoesNotExist:
            return Response({"error": "User is not associated with any company"}, status=status.HTTP_400_BAD_REQUEST)