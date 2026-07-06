"""
Middleware for handling CORS and ngrok-specific configurations.
"""
from django.utils.deprecation import MiddlewareMixin


class NowliiCORSMiddleware(MiddlewareMixin):
    """
    Enhanced CORS middleware for ngrok compatibility and Flutter integration.
    """
    
    def process_response(self, request, response):
        """Add CORS headers to responses."""
        
        # Allow all origins for development
        origin = request.META.get('HTTP_ORIGIN', '*')
        response['Access-Control-Allow-Origin'] = origin if origin else '*'
        
        # Allow credentials
        response['Access-Control-Allow-Credentials'] = 'true'
        
        # Allow common headers
        response['Access-Control-Allow-Headers'] = (
            'Content-Type, Authorization, X-Requested-With, '
            'Accept, Origin, X-CSRFToken, Access-Control-Request-Method, '
            'Access-Control-Request-Headers'
        )
        
        # Allow common methods
        response['Access-Control-Allow-Methods'] = (
            'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
        )
        
        # Expose common headers
        response['Access-Control-Expose-Headers'] = (
            'Content-Type, X-CSRFToken, Authorization'
        )
        
        return response

