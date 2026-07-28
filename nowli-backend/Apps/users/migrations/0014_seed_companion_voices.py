from django.db import migrations

# There is no inherent gender on the avatars, so we just assign a Male/Female mix.
# Everything defaults to Male (the field default); these names are flipped to Female.
# Matched case-insensitively so it works regardless of how the seed capitalized them.
FEMALE_NAMES = {"bloop", "fizzy", "zee", "cloudy", "glowy"}


def set_voices(apps, schema_editor):
    Option = apps.get_model("users", "NowliiPredefinedOption")
    for opt in Option.objects.all():
        opt.voice = "Female" if opt.name.strip().lower() in FEMALE_NAMES else "Male"
        opt.save(update_fields=["voice"])


def unset_voices(apps, schema_editor):
    # Reverse: reset everything to the default Male.
    Option = apps.get_model("users", "NowliiPredefinedOption")
    Option.objects.update(voice="Male")


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0013_nowliipredefinedoption_voice"),
    ]

    operations = [
        migrations.RunPython(set_voices, unset_voices),
    ]
