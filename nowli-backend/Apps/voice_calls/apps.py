from django.apps import AppConfig


class VoiceCallsConfig(AppConfig):
    name = 'Apps.voice_calls'

    def ready(self):
        # Registers the Quests post_save receiver that keeps ScheduledCall in step with the
        # quest it belongs to. Imported here (not at module level) so the app registry is
        # fully populated first.
        from . import signals  # noqa: F401
