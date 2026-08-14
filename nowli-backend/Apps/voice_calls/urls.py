from django.urls import path

from .views import (
    ScheduledCallDetailView,
    ScheduledCallListView,
    VoiceCallEndView,
    VoiceCallQuotaView,
    VoiceCallStartView,
    VoiceCallSummaryListView,
    VoiceCallSummaryNoteView,
    VoiceCallSummaryView,
)

app_name = "voice_calls"

# Keep the literal paths ABOVE `<int:pk>/…`: the detail routes would otherwise capture
# "scheduled" and "summaries" as a pk.
urlpatterns = [
    path('quota/', VoiceCallQuotaView.as_view(), name='voice-call-quota'),
    path('start/', VoiceCallStartView.as_view(), name='voice-call-start'),
    path('summaries/', VoiceCallSummaryListView.as_view(), name='voice-call-summaries'),
    path('scheduled/', ScheduledCallListView.as_view(), name='scheduled-call-list'),
    path('scheduled/<int:pk>/', ScheduledCallDetailView.as_view(), name='scheduled-call-detail'),
    path('<int:pk>/end/', VoiceCallEndView.as_view(), name='voice-call-end'),
    path('<int:pk>/summary/', VoiceCallSummaryView.as_view(), name='voice-call-summary'),
    path(
        '<int:pk>/summary/note/',
        VoiceCallSummaryNoteView.as_view(),
        name='voice-call-summary-note',
    ),
]
