from django.db import models


class StudentOnboarding(models.Model):
    student_full_name = models.CharField(max_length=120)
    student_age = models.PositiveSmallIntegerField()
    guardian_full_name = models.CharField(max_length=120)
    guardian_email = models.EmailField()
    guardian_phone = models.CharField(max_length=20)

    has_diagnosed_learning_difficulty = models.BooleanField()
    diagnosis_type = models.CharField(max_length=120, blank=True)

    requires_one_on_one_support = models.BooleanField()
    has_prior_lsa_experience = models.BooleanField()
    consent_to_data_processing = models.BooleanField()

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        app_label = "backend"
