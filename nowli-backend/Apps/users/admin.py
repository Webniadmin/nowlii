from django.contrib import admin
from .models import NowliiPredefinedOption, Profile

admin.site.register(Profile)


@admin.register(NowliiPredefinedOption)
class NowliiPredefinedOptionAdmin(admin.ModelAdmin):
    list_display = ('name', 'voice')
    list_editable = ('voice',)  # assign each avatar's Male/Female voice inline
    list_filter = ('voice',)
    search_fields = ('name',)
