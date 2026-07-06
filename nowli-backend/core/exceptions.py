"""
Custom exception handlers for API responses.
Ensures Flutter receives proper error responses with appropriate HTTP status codes.
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status


def custom_exception_handler(exc, context):
    """
    Custom exception handler that ensures proper error responses.
    This helps Flutter apps properly handle and display errors.
    """
    response = exception_handler(exc, context)

    if response is not None:
        # Add timestamp and error code for better debugging
        if isinstance(response.data, dict):
            response.data['status_code'] = response.status_code
        
        # Handle authentication errors specifically
        if response.status_code == status.HTTP_401_UNAUTHORIZED:
            response.data['error_type'] = 'AUTHENTICATION_REQUIRED'
            if 'detail' not in response.data:
                response.data['detail'] = 'Authentication credentials were not provided or are invalid.'
        
        # Handle permission errors
        elif response.status_code == status.HTTP_403_FORBIDDEN:
            response.data['error_type'] = 'PERMISSION_DENIED'
            if 'detail' not in response.data:
                response.data['detail'] = 'You do not have permission to perform this action.'
        
        # Handle not found errors
        elif response.status_code == status.HTTP_404_NOT_FOUND:
            response.data['error_type'] = 'NOT_FOUND'
            if 'detail' not in response.data:
                response.data['detail'] = 'The requested resource was not found.'
        
        # Handle validation errors
        elif response.status_code == status.HTTP_400_BAD_REQUEST:
            response.data['error_type'] = 'VALIDATION_ERROR'

        return response

    return response
