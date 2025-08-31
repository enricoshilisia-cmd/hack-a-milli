from django.core.management.base import BaseCommand
from universities.models import University
from datetime import datetime

class Command(BaseCommand):
    help = 'Populates the University model with Kenyan universities and their domains'

    def handle(self, *args, **kwargs):
        universities_data = [
            {"name": "University of Nairobi", "location": "Nairobi", "domain": "uonbi.ac.ke"},
            {"name": "Kenyatta University", "location": "Nairobi", "domain": "ku.ac.ke"},
            {"name": "Jomo Kenyatta University of Agriculture and Technology", "location": "Juja", "domain": "jkuat.ac.ke"},
            {"name": "Moi University", "location": "Eldoret", "domain": "mu.ac.ke"},
            {"name": "Egerton University", "location": "Njoro", "domain": "egerton.ac.ke"},
            {"name": "Maseno University", "location": "Maseno", "domain": "maseno.ac.ke"},
            {"name": "Technical University of Kenya", "location": "Nairobi", "domain": "tukenya.ac.ke"},
            {"name": "Technical University of Mombasa", "location": "Mombasa", "domain": "tum.ac.ke"},
            {"name": "Masinde Muliro University of Science and Technology", "location": "Kakamega", "domain": "mmust.ac.ke"},
            {"name": "Dedan Kimathi University of Technology", "location": "Nyeri", "domain": "dkut.ac.ke"},
            {"name": "Chuka University", "location": "Chuka", "domain": "chuka.ac.ke"},
            {"name": "Kisii University", "location": "Kisii", "domain": "kisiiuniversity.ac.ke"},
            {"name": "University of Eldoret", "location": "Eldoret", "domain": "uoeld.ac.ke"},
            {"name": "Karatina University", "location": "Karatina", "domain": "karu.ac.ke"},
            {"name": "Meru University of Science and Technology", "location": "Meru", "domain": "must.ac.ke"},
            {"name": "Multimedia University of Kenya", "location": "Nairobi", "domain": "mmu.ac.ke"},
            {"name": "South Eastern Kenya University", "location": "Kitui", "domain": "seku.ac.ke"},
            {"name": "University of Kabianga", "location": "Kericho", "domain": "kabianga.ac.ke"},
            {"name": "Laikipia University", "location": "Nyahururu", "domain": "laikipia.ac.ke"},
            {"name": "Machakos University", "location": "Machakos", "domain": "mksu.ac.ke"},
            {"name": "Kibabii University", "location": "Bungoma", "domain": "kibu.ac.ke"},
            {"name": "Maasai Mara University", "location": "Narok", "domain": "mmarau.ac.ke"},
            {"name": "Jaramogi Oginga Odinga University of Science and Technology", "location": "Bondo", "domain": "jooust.ac.ke"},
            {"name": "Pwani University", "location": "Kilifi", "domain": "pu.ac.ke"},
            {"name": "Taita Taveta University", "location": "Voi", "domain": "ttu.ac.ke"},
            {"name": "KCA University", "location": "Nairobi", "domain": "kcau.ac.ke"},
            {"name": "Africa Nazarene University", "location": "Nairobi", "domain": "anu.ac.ke"},
            {"name": "Daystar University", "location": "Nairobi", "domain": "daystar.ac.ke"},
            {"name": "United States International University Africa", "location": "Nairobi", "domain": "usiu.ac.ke"},
            {"name": "Strathmore University", "location": "Nairobi", "domain": "strathmore.edu"},
            {"name": "Catholic University of Eastern Africa", "location": "Nairobi", "domain": "cuea.edu"},
            {"name": "Mount Kenya University", "location": "Thika", "domain": "mku.ac.ke"},
            {"name": "Kenya Methodist University", "location": "Meru", "domain": "kemu.ac.ke"},
            {"name": "Pan Africa Christian University", "location": "Nairobi", "domain": "pacu.ac.ke"},
            {"name": "St. Paul's University", "location": "Limuru", "domain": "spu.ac.ke"},
            {"name": "Africa International University", "location": "Nairobi", "domain": "aiu.ac.ke"},
            {"name": "KAG East University", "location": "Nairobi", "domain": "east.ac.ke"},
            {"name": "Great Lakes University of Kisumu", "location": "Kisumu", "domain": "gluk.ac.ke"},
            {"name": "Adventist University of Africa", "location": "Nairobi", "domain": "aua.ac.ke"},
            {"name": "Gretsa University", "location": "Thika", "domain": "gretsauniversity.ac.ke"},
            {"name": "Pioneer International University", "location": "Nairobi", "domain": "piu.ac.ke"},
            {"name": "Umma University", "location": "Kajiado", "domain": "umma.ac.ke"},
            {"name": "Kirinyaga University", "location": "Kerugoya", "domain": "kyu.ac.ke"},
            {"name": "Murang'a University of Technology", "location": "Murang'a", "domain": "mut.ac.ke"},
            {"name": "Rongo University", "location": "Rongo", "domain": "rongovarsity.ac.ke"},
            {"name": "Co-operative University of Kenya", "location": "Nairobi", "domain": "cuk.ac.ke"},
            {"name": "Garissa University", "location": "Garissa", "domain": "gau.ac.ke"},
            {"name": "Alupe University", "location": "Busia", "domain": "auc.ac.ke"},
            {"name": "Tom Mboya University", "location": "Homa Bay", "domain": "tmu.ac.ke"},
            {"name": "Tharaka University", "location": "Tharaka Nithi", "domain": "tharaka.ac.ke"},
            {"name": "Lukenya University", "location": "Machakos", "domain": "lukenyauniversity.ac.ke"},
            {"name": "University of Embu", "location": "Embu", "domain": "embuni.ac.ke"},
            {"name": "National Defence University", "location": "Nakuru", "domain": "ndu.ac.ke"},
            {"name": "Open University of Kenya", "location": "Konza Technopolis", "domain": "ouk.ac.ke"},
            {"name": "Kaimosi Friends University", "location": "Vihiga", "domain": "kafu.ac.ke"},
            {"name": "University of Eastern Africa, Baraton", "location": "Eldoret", "domain": "ueab.ac.ke"},
            {"name": "Scott Christian University", "location": "Machakos", "domain": "scott.ac.ke"},
            {"name": "Kabarak University", "location": "Nakuru", "domain": "kabarak.ac.ke"},
            {"name": "Zetech University", "location": "Nairobi", "domain": "zetech.ac.ke"},
            {"name": "Kenya Highlands University", "location": "Kericho", "domain": "khu.ac.ke"},
            {"name": "Presbyterian University of East Africa", "location": "Kikuyu", "domain": "puea.ac.ke"},
            {"name": "Management University of Africa", "location": "Nairobi", "domain": "mua.ac.ke"},
            {"name": "Amref International University", "location": "Nairobi", "domain": "amiu.ac.ke"},
            {"name": "Riara University", "location": "Nairobi", "domain": "riarauniversity.ac.ke"},
            {"name": "International Leadership University", "location": "Nairobi", "domain": "ilu.ac.ke"},
        ]

        created_count = 0
        updated_count = 0
        skipped_count = 0

        for uni_data in universities_data:
            try:
                university, created = University.objects.get_or_create(
                    domain=uni_data['domain'],
                    defaults={
                        'name': uni_data['name'],
                        'location': uni_data['location'],
                        'is_verified': True,
                        'verified_at': datetime.now()
                    }
                )
                if created:
                    created_count += 1
                    self.stdout.write(self.style.SUCCESS(f"Created university: {uni_data['name']}"))
                else:
                    # Update existing university if needed
                    if university.name != uni_data['name'] or university.location != uni_data['location']:
                        university.name = uni_data['name']
                        university.location = uni_data['location']
                        university.is_verified = True
                        university.verified_at = datetime.now()
                        university.save()
                        updated_count += 1
                        self.stdout.write(self.style.WARNING(f"Updated university: {uni_data['name']}"))
                    else:
                        skipped_count += 1
                        self.stdout.write(self.style.NOTICE(f"Skipped existing university: {uni_data['name']}"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error processing {uni_data['name']}: {str(e)}"))

        self.stdout.write(self.style.SUCCESS(
            f"\nSummary: Created {created_count} universities, "
            f"Updated {updated_count} universities, "
            f"Skipped {skipped_count} universities"
        ))