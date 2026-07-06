from django.core.management.base import BaseCommand
from Apps.users.models import NowliiPredefinedOption
from django.core.files import File
import os

class Command(BaseCommand):
    help = 'Populate NowliiPredefinedOption with all characters in media/nowlii_logos'

    def handle(self, *args, **options):
        logo_dir = os.path.join('media', 'nowlii_logos')
        
        if not os.path.exists(logo_dir):
            self.stdout.write(self.style.ERROR(f'Directory {logo_dir} does not exist.'))
            return

        for filename in os.listdir(logo_dir):
            if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                # Use filename as name, capitalized
                name = os.path.splitext(filename)[0].capitalize()
                
                image_path = os.path.join(logo_dir, filename)
                
                self.stdout.write(f'Processing {name} ({filename})...')
                
                obj, created = NowliiPredefinedOption.objects.get_or_create(name=name)
                
                with open(image_path, 'rb') as f:
                    obj.avatar_logo.save(filename, File(f), save=True)
                
                status = "created" if created else "updated"
                self.stdout.write(self.style.SUCCESS(f'Successfully {status} {name} and uploaded to S3'))

        self.stdout.write(self.style.SUCCESS('Finished populating NowliiPredefinedOption'))
