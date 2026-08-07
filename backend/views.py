import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .models import StudentOnboarding
from .serializers import StudentOnboardingSerializer


@require_http_methods(["GET"])
def health_check(request):
    return JsonResponse({"status": "ok", "service": "backend"})


@csrf_exempt
@require_http_methods(["GET", "POST"])
def student_onboarding(request):
    if request.method == "GET":
        records = list(
            StudentOnboarding.objects.order_by("-created_at").values(
                "id",
                "student_full_name",
                "student_age",
                "guardian_full_name",
                "guardian_email",
                "guardian_phone",
                "has_diagnosed_learning_difficulty",
                "diagnosis_type",
                "requires_one_on_one_support",
                "has_prior_lsa_experience",
                "consent_to_data_processing",
                "created_at",
            )
        )
        return JsonResponse({"results": records})

    try:
        payload = json.loads(request.body.decode("utf-8") or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"detail": "Invalid JSON payload."}, status=400)

    serializer = StudentOnboardingSerializer(data=payload)
    if not serializer.is_valid():
        return JsonResponse({"errors": serializer.errors}, status=400)

    instance = serializer.save()
    response_serializer = StudentOnboardingSerializer(instance)
    return JsonResponse(response_serializer.data, status=201)
