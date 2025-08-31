from django.urls import path
from .views import (
    StudentRegisterView, CompanyRegisterView, MentorRegisterView,
    AdminRegisterView, LoginView, PendingSchoolDomainListView,
    PendingSchoolDomainApproveView, PendingCompanyDomainListView,
    PendingCompanyDomainApproveView, GraduateRegisterView, 
    ProfileUpdateView, ProfileView
)


urlpatterns = [
    path('register/student/', StudentRegisterView.as_view(), name='student_register'),
    path('register/graduate/', GraduateRegisterView.as_view(), name='graduate_register'),
    path('register/company/', CompanyRegisterView.as_view(), name='company_register'),
    path('register/mentor/', MentorRegisterView.as_view(), name='mentor_register'),
    path('register/admin/', AdminRegisterView.as_view(), name='admin_register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile_update'),
    path('pending/school-domains/', PendingSchoolDomainListView.as_view(), name='pending_school_domains'),
    path('pending/school-domains/<int:pk>/approve/', PendingSchoolDomainApproveView.as_view(), name='approve_school_domain'),
    path('pending/company-domains/', PendingCompanyDomainListView.as_view(), name='pending_company_domains'),
    path('pending/company-domains/<int:pk>/approve/', PendingCompanyDomainApproveView.as_view(), name='approve_company_domain'),
]