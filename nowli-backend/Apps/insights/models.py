from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class InsightCache(models.Model):
    """
    Optional: cache AI-generated insight text per user per period
    so we don't call the AI API on every request.
    """
    PERIOD_CHOICES = [
        ('weekly',  'Weekly'),
        ('monthly', 'Monthly'),
    ]

    user       = models.ForeignKey(User, on_delete=models.CASCADE, related_name='insight_caches')
    period     = models.CharField(max_length=10, choices=PERIOD_CHOICES)
    period_key = models.CharField(max_length=20)   # e.g. "2026-W15" or "2026-04"
    payload    = models.JSONField()                 # full AI insight JSON
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together  = ('user', 'period', 'period_key')
        verbose_name     = 'Insight Cache'
        verbose_name_plural = 'Insight Caches'

    def __str__(self):
        return f"{self.user} | {self.period} | {self.period_key}"
