from django.contrib import admin
from django.urls import path, include, re_path
from django.shortcuts import redirect
from django.conf import settings
from django.conf.urls.static import static

from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
schema_view = get_schema_view(
    openapi.Info(
        title="✨ NOWLII API Documentation | Made by Md Fahad Mir ✨",
        default_version='v1',
        description="API documentation for the NOWLII project",
        
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

def redirect_to_docs(request):
    """Redirect root URL to API documentation"""
    return redirect('schema-swagger-ui')

urlpatterns = [
    path('admin/', admin.site.urls),

    path('api/', include('Apps.users.urls')),
    # Keep the explicit subtasks/generate/ route ABOVE the quests router include:
    # Apps.quests.urls now registers a `subtasks` viewset whose detail route
    # (subtasks/<pk>/) would otherwise capture `subtasks/generate/` (pk="generate")
    # and shadow this endpoint.
    path("api/subtasks/", include("Apps.subtask_generator.urls")),
    path('api/', include('Apps.quests.urls')),
    path("api/", include("Apps.insights.urls")),
    path("api/support/", include("Apps.support.urls")),
    path("api/voice-calls/", include("Apps.voice_calls.urls")),

    path('accounts/', include('allauth.urls')),
    

    # API Documentation
    path('api/docs/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('api/swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),

    # Redirect root to docs
    path('', redirect_to_docs, name='root-redirect'),

]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
