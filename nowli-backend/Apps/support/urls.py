from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import SupportMessageViewSet

app_name = "support"

router = DefaultRouter()
router.register(r'messages', SupportMessageViewSet, basename='support-messages')

urlpatterns = [
    path('', include(router.urls)),
]
