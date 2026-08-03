from rest_framework import serializers


class PhaseSerializer(serializers.Serializer):
    from_month = serializers.IntegerField()
    to_month   = serializers.IntegerField()
    price      = serializers.FloatField()


class PlanScheduleSerializer(serializers.Serializer):
    currency         = serializers.CharField()
    free_after_month = serializers.IntegerField()
    phases           = PhaseSerializer(many=True)


class StepDownSerializer(serializers.Serializer):
    """What the app must do to keep the user's price in step with the schedule.

    Exists because neither store offers a server-side plan change — the backend can only
    say what should happen and the device has to carry it out.
    """
    due          = serializers.BooleanField()
    cancel       = serializers.BooleanField()
    from_product = serializers.CharField(allow_blank=True)
    to_product   = serializers.CharField(allow_blank=True)
    to_price     = serializers.FloatField()


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
    # Free-trial block. `in_trial` + `trial_days_left` drive the in-app countdown; when the
    # trial is over and nothing was purchased, `has_access` goes False and the app paywalls.
    in_trial         = serializers.BooleanField(required=False)
    trial_days_left  = serializers.IntegerField(required=False)
    trial_ends_at    = serializers.DateField(required=False, allow_null=True)
    trial_days_total = serializers.IntegerField(required=False)
    trial_used       = serializers.BooleanField(required=False)
    # Present for every caller; `due`/`cancel` are False for anyone it does not apply to.
    step_down        = StepDownSerializer(required=False)
