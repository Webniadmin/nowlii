from django.urls import path
from .views import GenerateSubTasksView

app_name = "subtasks_generator"

urlpatterns = [
    path("generate/", GenerateSubTasksView.as_view(), name="generate"),
]