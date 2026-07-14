from rest_framework import serializers


class PhaseSerializer(serializers.Serializer):
    from_month = serializers.IntegerField()
    to_month   = serializers.IntegerField()
    price      = serializers.FloatField()


class PlanScheduleSerializer(serializers.Serializer):
    currency         = serializers.CharField()
    free_after_month = serializers.IntegerField()
    phases           = PhaseSerializer(many=True)


class SubscriptionStatusSerializer(serializers.Serializer):
    subscribed    = serializers.BooleanField()
    status        = serializers.CharField()
    currency      = serializers.CharField(required=False)
    platform      = serializers.CharField(required=False)
    started_at    = serializers.DateField(required=False, allow_null=True)
    month_index   = serializers.IntegerField(required=False)
    phase         = serializers.CharField(required=False)
    current_price = serializers.FloatField(required=False)
    next_price    = serializers.FloatField(required=False)
    is_free       = serializers.BooleanField(required=False)
    lifetime_free = serializers.BooleanField(required=False)
    has_access    = serializers.BooleanField(required=False)
