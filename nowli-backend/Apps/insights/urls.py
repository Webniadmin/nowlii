from django.urls import path
from .views import AIInsightView, RestDaysView

app_name = "insights"

urlpatterns = [
    path("insights/", AIInsightView.as_view(), name="insights"),
    path("insights/rest-days/", RestDaysView.as_view(), name="insights-rest-days"),
]
