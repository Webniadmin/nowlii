from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import QuestsViewset, SubTasksViewset


router = DefaultRouter()
router.register(r'quests', QuestsViewset)
router.register(r'subtasks', SubTasksViewset)

urlpatterns = [
    path('', include(router.urls)),
]