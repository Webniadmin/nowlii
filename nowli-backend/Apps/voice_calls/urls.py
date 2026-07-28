from django.urls import path

from .views import (
    VoiceCallEndView,
    VoiceCallQuotaView,
    VoiceCallStartView,
    VoiceCallSummaryListView,
    VoiceCallSummaryView,
)

app_name = "voice_calls"

urlpatterns = [
    path('quota/', VoiceCallQuotaView.as_view(), name='voice-call-quota'),
    path('start/', VoiceCallStartView.as_view(), name='voice-call-start'),
    path('summaries/', VoiceCallSummaryListView.as_view(), name='voice-call-summaries'),
    path('<int:pk>/end/', VoiceCallEndView.as_view(), name='voice-call-end'),
    path('<int:pk>/summary/', VoiceCallSummaryView.as_view(), name='voice-call-summary'),
]
