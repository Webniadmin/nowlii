from django.db import migrations


def to_female(apps, schema_editor):
    """Move existing profiles and companions onto the female voice.

    Changing a field default only affects rows created afterwards, and every account on the
    system predates that change — so without this, "the default is female" would be true for
    nobody who already exists.

    Deliberately unconditional rather than "only where voice is empty": the old default wrote
    'Male' into every row on creation, so an empty-only backfill would find nothing. Anyone
    who wants the male voice can pick it in AI Personalization, and that choice survives from
    here on.
    """
    apps.get_model('users', 'Profile').objects.update(voice='Female')
    apps.get_model('users', 'NowliiPredefinedOption').objects.update(voice='Female')


def to_male(apps, schema_editor):
    """Reverse: back to the previous 'Male' default.

    This cannot restore per-user choices — they were not recorded anywhere else — so it
    restores the old default rather than the old data. Noted so nobody expects otherwise.
    """
    apps.get_model('users', 'Profile').objects.update(voice='Male')
    apps.get_model('users', 'NowliiPredefinedOption').objects.update(voice='Male')


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0017_profile_restricted_topics_and_more'),
    ]

    operations = [
        migrations.RunPython(to_female, to_male),
    ]
