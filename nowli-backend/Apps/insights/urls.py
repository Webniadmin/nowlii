from django.urls import path
from .views import AIInsightView

app_name = "insights"

urlpatterns = [
    path("insights/", AIInsightView.as_view(), name="insights"),
]
