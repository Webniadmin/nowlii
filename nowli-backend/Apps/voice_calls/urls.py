from django.urls import path

from .views import VoiceCallEndView, VoiceCallQuotaView, VoiceCallStartView

app_name = "voice_calls"

urlpatterns = [
    path('quota/', VoiceCallQuotaView.as_view(), name='voice-call-quota'),
    path('start/', VoiceCallStartView.as_view(), name='voice-call-start'),
    path('<int:pk>/end/', VoiceCallEndView.as_view(), name='voice-call-end'),
]
