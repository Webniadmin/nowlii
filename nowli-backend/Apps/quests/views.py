from datetime import date, timedelta

from django.db.models import Q, Count, F
from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from .models import Quests, SubTasks
from .serializers import QuestsSerializers, SubTasksSerializers, SubTasksCrudSerializers
from django.utils.decorators import method_decorator
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema


# ------------------------------------------------------------------------------
# QUESTS
# ------------------------------------------------------------------------------
@method_decorator(name='list', decorator=swagger_auto_schema(
    operation_summary="List all quests",
    operation_description="Get a list of all quests entries.",
    tags=['Quests'],
    manual_parameters=[
        openapi.Parameter(
            'due_date',
            openapi.IN_QUERY,
            description='Filter quests by select_a_date only. Use YYYY-MM-DD format.',
            type=openapi.TYPE_STRING,
            required=False,
            example='2026-04-05'
        ),
    ]
))
@method_decorator(name='create', decorator=swagger_auto_schema(
    operation_summary="Create quest",
    operation_description="Create a new profile entry.",
    tags=['Quests']
))
@method_decorator(name='retrieve', decorator=swagger_auto_schema(
    operation_summary="Get quest details",
    operation_description="Get details of a specific quest entry by ID.",
    tags=['Quests']
))
@method_decorator(name='update', decorator=swagger_auto_schema(
    operation_summary="Update quest",
    operation_description="Update a specific quest entry by ID.",
    tags=['Quests']
))
@method_decorator(name='partial_update', decorator=swagger_auto_schema(
    operation_summary="Partially update quest",
    operation_description="Partially update a specific quest entry by ID.",
    tags=['Quests']
))
@method_decorator(name='destroy', decorator=swagger_auto_schema(
    operation_summary="Delete quest",
    operation_description="Delete a specific quest entry by ID.",
    tags=['Quests']
))
class QuestsViewset(viewsets.ModelViewSet):
    queryset = Quests.objects.all()
    serializer_class = QuestsSerializers
    permission_classes = [IsAuthenticated]


    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return Quests.objects.none()
            
        queryset = super().get_queryset().filter(user=self.request.user)
        filter_value = self.request.query_params.get('due_date')

        if filter_value:
            queryset = queryset.filter(select_a_date=filter_value)

        return queryset

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @swagger_auto_schema(
        operation_summary="Bulk delete quests",
        operation_description="Delete multiple quests at once by providing a list of IDs.",
        tags=['Quests'],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            required=['ids'],
            properties={
                'ids': openapi.Schema(
                    type=openapi.TYPE_ARRAY, 
                    items=openapi.Items(type=openapi.TYPE_INTEGER),
                    description="List of Quest IDs to delete",
                    example=[1, 2, 3]
                ),
            },
        ),
        responses={
            204: "Successfully deleted",
            400: "Invalid input"
        }
    )
    @action(detail=False, methods=['delete'], url_path='bulk-delete')
    def bulk_delete(self, request):
        """
        Deletes multiple quests at once.
        Expects a JSON body: {"ids": [1, 2, 3]}
        """
        ids = request.data.get('ids', [])
        
        if not ids:
            return Response(
                {"error": "No IDs provided in the request body."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # We use self.get_queryset() to ensure users can only delete THEIR OWN quests
        queryset = self.get_queryset().filter(id__in=ids)
        deleted_count, _ = queryset.delete()

        return Response(
            {"message": f"Successfully deleted {deleted_count} quests."}, 
            status=status.HTTP_204_NO_CONTENT
        )    

    @swagger_auto_schema(
        operation_summary="Calculate user streak",
        operation_description="Returns the current number of consecutive days where all quests for that day were completed.",
        tags=['Quests'],
        responses={
            200: openapi.Response(
                description="Current streak count",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'streak': openapi.Schema(type=openapi.TYPE_INTEGER, example=5)
                    }
                )
            )
        }
    )
    @action(detail=False, methods=['get'], url_path='streak')
    def streak(self, request):
        # Get dates where all quests for that date are done
        completed_dates = Quests.objects.filter(
            user=request.user, select_a_date__isnull=False
        ).values('select_a_date').annotate(
            total=Count('id'),
            done=Count('id', filter=Q(task_done=True))
        ).filter(total__gt=0, total=F('done')).values_list('select_a_date', flat=True).distinct().order_by('-select_a_date')

        if not completed_dates:
            return Response({'streak': 0}, status=status.HTTP_200_OK)

        # Find current streak: consecutive days ending with the latest completed date
        completed_dates = sorted(set(completed_dates), reverse=True)
        streak = 0
        for i, d in enumerate(completed_dates):
            if i == 0:
                streak = 1
            elif (completed_dates[i-1] - d).days == 1:
                streak += 1
            else:
                break
        return Response({'streak': streak}, status=status.HTTP_200_OK)


# ------------------------------------------------------------------------------
# SUBTASKS
# ------------------------------------------------------------------------------
@method_decorator(name='list', decorator=swagger_auto_schema(
    operation_summary="List all subtasks",
    operation_description="Get a list of all subtasks entries.",
    tags=['SubTasks']
))
@method_decorator(name='create', decorator=swagger_auto_schema(
    operation_summary="Create subtask",
    operation_description="Create a new subtask entry.",
    tags=['SubTasks']
))
@method_decorator(name='retrieve', decorator=swagger_auto_schema(
    operation_summary="Get subtask details",
    operation_description="Get details of a specific subtask entry by ID.",
    tags=['SubTasks']
))
@method_decorator(name='update', decorator=swagger_auto_schema(
    operation_summary="Update subtask",
    operation_description="Update a specific subtask entry by ID.",
    tags=['SubTasks']
))
@method_decorator(name='partial_update', decorator=swagger_auto_schema(
    operation_summary="Partially update subtask",
    operation_description="Partially update a specific subtask entry by ID.",
    tags=['SubTasks']
))
@method_decorator(name='destroy', decorator=swagger_auto_schema(
    operation_summary="Delete subtask",
    operation_description="Delete a specific subtask entry by ID.",
    tags=['SubTasks']
))
class SubTasksViewset(viewsets.ModelViewSet):
    queryset = SubTasks.objects.all()
    serializer_class = SubTasksCrudSerializers
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return SubTasks.objects.none()

        return super().get_queryset().filter(task__user=self.request.user)

    def _assert_owns_task(self, task):
        """A user may only attach/keep a subtask on one of their own quests."""
        if task is not None and task.user_id != self.request.user.id:
            raise PermissionDenied("You can only manage subtasks of your own quests.")

    def perform_create(self, serializer):
        self._assert_owns_task(serializer.validated_data.get('task'))
        serializer.save()

    def perform_update(self, serializer):
        self._assert_owns_task(serializer.validated_data.get('task'))
        serializer.save()