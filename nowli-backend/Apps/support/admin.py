from django import forms
from django.conf import settings
from django.contrib import admin
from django.core.mail import send_mail

from .models import SupportMessage


class SupportMessageAdminForm(forms.ModelForm):
    """Adds a 'Reply' box so support can answer straight from a message's page."""

    reply = forms.CharField(
        required=False,
        label="✏️ Reply to this user",
        help_text="Type a reply here and click SAVE — it is sent to this user as an admin "
                  "message, shows up in their in-app Support chat, and they get an email. "
                  "(Leave empty if you're just viewing.)",
        widget=forms.Textarea(attrs={'rows': 3, 'style': 'width: 90%;'}),
    )

    class Meta:
        model = SupportMessage
        fields = '__all__'


@admin.register(SupportMessage)
class SupportMessageAdmin(admin.ModelAdmin):
    form = SupportMessageAdminForm
    fields = ('user', 'sender', 'category', 'body', 'is_read', 'created_at', 'reply')
    list_display = ('created_at', 'user', 'sender', 'category', 'short_body', 'is_read')
    list_filter = ('sender', 'category', 'is_read', 'created_at')
    search_fields = ('user__email', 'body')
    readonly_fields = ('created_at',)
    list_select_related = ('user',)

    @admin.display(description='message')
    def short_body(self, obj):
        return (obj.body[:60] + '…') if len(obj.body or '') > 60 else obj.body

    def get_changeform_initial_data(self, request):
        # If you ever add a message directly (not via the Reply box), default it to admin.
        return {'sender': 'admin'}

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        reply_text = (form.cleaned_data.get('reply') or '').strip()
        if reply_text:
            # Open any of the user's messages, type into "Reply", save → new admin reply.
            SupportMessage.objects.create(user=obj.user, sender='admin', body=reply_text)
            self._email_user(obj.user, reply_text)
        elif obj.sender == 'admin' and not change:
            # Or a brand-new admin message added directly.
            self._email_user(obj.user, obj.body)

    def _email_user(self, user, body):
        try:
            send_mail(
                subject="You have a reply from NOWLII support",
                message=f"{body}\n\nOpen the Support tab in the app to see the full conversation.",
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except Exception:
            pass
