from django.core.management.base import BaseCommand
from Apps.quests.models import Quests, SubTasks
from django.contrib.auth import get_user_model
import json

class Command(BaseCommand):
    help = 'Add initial quests for a specific user'

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='Email of the user to add quests for')

    def handle(self, *args, **options):
        User = get_user_model()
        email = options['email']
        
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'User {email} not found.'))
            return

        quests_data = [
          {
            "subtasks": [
              { "title": "clean sink", "task_done": False },
              { "title": "wash tiles", "task_done": True }
            ],
            "task": "bathroom cleaning",
            "zone": "Elevated",
            "select_a_date": "2026-04-15",
            "enable_call": True,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "cut vegetables", "task_done": True },
              { "title": "cook meal", "task_done": False }
            ],
            "task": "prepare food",
            "zone": "Soft steps",
            "select_a_date": "2026-04-16",
            "enable_call": False,
            "repeat_quest": True,
            "set_alarm": False,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "sort files", "task_done": False },
              { "title": "backup data", "task_done": False }
            ],
            "task": "organize files",
            "zone": "Stretch zone",
            "select_a_date": "2026-04-17",
            "enable_call": True,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "pushups", "task_done": True },
              { "title": "running", "task_done": False }
            ],
            "task": "workout",
            "zone": "Power move",
            "select_a_date": "2026-04-18",
            "enable_call": False,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "check list", "task_done": True },
              { "title": "buy items", "task_done": False }
            ],
            "task": "shopping",
            "zone": "Elevated",
            "select_a_date": "2026-04-19",
            "enable_call": True,
            "repeat_quest": True,
            "set_alarm": False,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "dust table", "task_done": False },
              { "title": "clean floor", "task_done": True }
            ],
            "task": "room cleaning",
            "zone": "Soft steps",
            "select_a_date": "2026-04-20",
            "enable_call": False,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "watch lesson", "task_done": True },
              { "title": "practice coding", "task_done": False }
            ],
            "task": "study coding",
            "zone": "Stretch zone",
            "select_a_date": "2026-04-21",
            "enable_call": True,
            "repeat_quest": True,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "stretching", "task_done": False },
              { "title": "cardio", "task_done": False }
            ],
            "task": "fitness",
            "zone": "Power move",
            "select_a_date": "2026-04-22",
            "enable_call": False,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "call mom", "task_done": True },
              { "title": "talk 15 min", "task_done": False }
            ],
            "task": "family call",
            "zone": "Soft steps",
            "select_a_date": "2026-04-23",
            "enable_call": True,
            "repeat_quest": False,
            "set_alarm": False,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "breathing", "task_done": False },
              { "title": "relax", "task_done": False }
            ],
            "task": "meditation",
            "zone": "Elevated",
            "select_a_date": "2026-04-24",
            "enable_call": False,
            "repeat_quest": True,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "select topic", "task_done": True },
              { "title": "read notes", "task_done": False }
            ],
            "task": "study",
            "zone": "Stretch zone",
            "select_a_date": "2026-04-25",
            "enable_call": True,
            "repeat_quest": False,
            "set_alarm": False,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "jogging", "task_done": False },
              { "title": "cool down", "task_done": False }
            ],
            "task": "morning run",
            "zone": "Power move",
            "select_a_date": "2026-04-26",
            "enable_call": False,
            "repeat_quest": True,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "buy items", "task_done": True },
              { "title": "arrange room", "task_done": False }
            ],
            "task": "decorate",
            "zone": "Soft steps",
            "select_a_date": "2026-04-27",
            "enable_call": True,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "review tasks", "task_done": False },
              { "title": "plan next", "task_done": False }
            ],
            "task": "planning",
            "zone": "Elevated",
            "select_a_date": "2026-04-28",
            "enable_call": False,
            "repeat_quest": False,
            "set_alarm": True,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "read article", "task_done": True },
              { "title": "note points", "task_done": False }
            ],
            "task": "learning",
            "zone": "Stretch zone",
            "select_a_date": "2026-04-29",
            "enable_call": True,
            "repeat_quest": False,
            "set_alarm": False,
            "task_done": False
          },
          {
            "subtasks": [
              { "title": "exercise", "task_done": False },
              { "title": "stretch", "task_done": False }
            ],
            "task": "daily workout",
            "zone": "Power move",
            "select_a_date": "2026-04-30",
            "enable_call": False,
            "repeat_quest": True,
            "set_alarm": True,
            "task_done": False
          }
        ]

        for q_data in quests_data:
            subtasks_list = q_data.pop('subtasks')
            quest = Quests.objects.create(user=user, **q_data)
            self.stdout.write(f'Created quest: {quest.task}')
            
            for s_data in subtasks_list:
                SubTasks.objects.create(task=quest, **s_data)
                self.stdout.write(f'  Created subtask: {s_data["title"]}')

        self.stdout.write(self.style.SUCCESS('Successfully added all quests.'))
