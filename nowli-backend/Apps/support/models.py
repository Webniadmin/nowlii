from django.conf import settings
from django.db import models


class SupportMessage(models.Model):
    """One message in a user's support conversation. All messages for a given user
    form their thread; ``sender`` distinguishes the user from an admin reply."""

    SENDER_CHOICES = [('user', 'user'), ('admin', 'admin')]
    CATEGORY_CHOICES = [
        ('App issue', 'App issue'),
        ('Billing & Subscription', 'Billing & Subscription'),
        ('Question about features', 'Question about features'),
        ('Feedback or suggestion', 'Feedback or suggestion'),
        ('Other', 'Other'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='support_messages',
    )
    sender = models.CharField(max_length=10, choices=SENDER_CHOICES, default='user')
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, blank=True, null=True)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        verbose_name = 'Support message'
        verbose_name_plural = 'Support messages'

    def __str__(self):
        return f"[{self.sender}] {self.user.email}: {self.body[:40]}"
