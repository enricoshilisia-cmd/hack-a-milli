"""
URL configuration for skillproof project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf.urls.static import static
from django.conf import settings

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),               # API endpoints for users (e.g., auth, profiles)
    path('api/companies/', include('companies.urls')),       # API for companies (e.g., create company, plans)
    #path('api/challenges/', include('challenges.urls')),     # API for challenges (e.g., list, create, details)
    #path('api/submissions/', include('submissions.urls')),   # API for submissions (e.g., submit, list)
    #path('api/evaluations/', include('evaluations.urls')),   # API for evaluations (e.g., get scores, logs)
    path('api/badges/', include('badges.urls')),             # API for badges (e.g., list, award)
    #path('api/portfolio/', include('portfolio.urls')),       # API for portfolios (e.g., view, update)
    #path('api/recruiters/', include('recruiters.urls')),     # API for recruiters (e.g., search, shortlist)
    #path('api/mentors/', include('mentors.urls')),           # API for mentors (e.g., assignments, sessions)
    #path('api/notifications/', include('notifications.urls')), # API for notifications (e.g., list, mark read)
    #path('api/payments/', include('payments.urls')),         # API for payments (e.g., subscriptions, transactions)
    #path('api/analytics/', include('analytics.urls')),       # API for analytics (e.g., get stats)
    #path('api/universities/', include('universities.urls')), # API for universities (e.g., enrollments)
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# ✅ Serve static files (CSS, JS, admin files) in development
if settings.DEBUG:
    from pathlib import Path
    urlpatterns += static(settings.STATIC_URL, document_root=Path(settings.BASE_DIR) / "static")