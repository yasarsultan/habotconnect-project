from django.urls import path

from .views import health_check, student_onboarding

urlpatterns = [
    path("health/", health_check, name="health-check"),
    path("student-onboarding/", student_onboarding, name="student-onboarding"),
]
