from typing import ClassVar

from rest_framework import serializers

from .dcyn import ALLOWED_DCYN_VALUES, from_dcyn, to_dcyn
from .models import StudentOnboarding


class DCYNField(serializers.Field):
    def to_internal_value(self, data):
        try:
            return from_dcyn(to_dcyn(data))
        except ValueError:
            raise serializers.ValidationError(
                f"Value must resolve to one of {sorted(ALLOWED_DCYN_VALUES)}"
            )

    def to_representation(self, value):
        return to_dcyn(value)


class StudentOnboardingSerializer(serializers.ModelSerializer):
    has_diagnosed_learning_difficulty = DCYNField()
    requires_one_on_one_support = DCYNField()
    has_prior_lsa_experience = DCYNField()
    consent_to_data_processing = DCYNField()

    class Meta:
        model = StudentOnboarding
        fields: ClassVar[list[str]] = [
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
        ]
        read_only_fields: ClassVar[list[str]] = ["id", "created_at"]

    def validate_student_full_name(self, value):
        cleaned = value.strip()
        if len(cleaned) < 2:
            raise serializers.ValidationError("Student full name is too short.")
        if not all(part.isalpha() or part in (" ", "-", "'") for part in cleaned):
            raise serializers.ValidationError(
                "Student full name contains invalid characters."
            )
        return cleaned

    def validate_student_age(self, value):
        if value < 3 or value > 18:
            raise serializers.ValidationError("Student age must be between 3 and 18.")
        return value

    def validate_guardian_phone(self, value):
        digits = "".join(ch for ch in value if ch.isdigit())
        if len(digits) < 8 or len(digits) > 15:
            raise serializers.ValidationError(
                "Guardian phone number length is invalid."
            )
        return value

    def validate(self, data):
        has_diagnosis = data.get("has_diagnosed_learning_difficulty")
        diagnosis_type = data.get("diagnosis_type", "").strip()

        if has_diagnosis and not diagnosis_type:
            raise serializers.ValidationError(
                {
                    "diagnosis_type": "Required when has_diagnosed_learning_difficulty is Y."
                }
            )
        if not has_diagnosis and diagnosis_type:
            raise serializers.ValidationError(
                {
                    "diagnosis_type": "Must be blank when has_diagnosed_learning_difficulty is N."
                }
            )

        if not data.get("consent_to_data_processing"):
            raise serializers.ValidationError(
                {
                    "consent_to_data_processing": "Consent is required to submit this form."
                }
            )

        return data
