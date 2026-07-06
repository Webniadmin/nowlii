from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

# ------------------------------------------------------------------------------
# QUESTS
# ------------------------------------------------------------------------------
class Quests(models.Model):
    ZONE_CHOICES= [
        ('Soft steps', 'Soft steps'),
        ('Elevated', 'Elevated'),
        ('Power move', 'Power move'),
        ('Stretch zone', 'Stretch zone'),
    ]


    user = models.ForeignKey(User, on_delete=models.CASCADE)
    task = models.CharField(max_length=200, blank=True, null=True)
    zone = models.CharField(max_length=100, choices=ZONE_CHOICES, blank=True, null=True)
    select_a_time = models.TimeField(blank=True, null=True)
    select_a_date = models.DateField(blank=True, null=True)
    enable_call = models.BooleanField(default=False)
    repeat_quest = models.BooleanField(default=False)
    set_alarm = models.BooleanField(default=False)
    task_done = models.BooleanField(default=False)


    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

    def __str__(self):
        return self.task
    
    class Meta:
        verbose_name_plural = 'Quests'


# ------------------------------------------------------------------------------
# SUBTASKS
# ------------------------------------------------------------------------------
class SubTasks(models.Model):
    task = models.ForeignKey(Quests, related_name='subtasks', on_delete=models.CASCADE)
    title = models.CharField(max_length=50, blank=True, null=True)
    task_done = models.BooleanField(default=False)

    def __str__(self):
        return self.title
    
    class Meta:
        verbose_name_plural = 'subtasks'