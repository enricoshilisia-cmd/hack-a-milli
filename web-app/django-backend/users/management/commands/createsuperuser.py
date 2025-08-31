from django.contrib.auth.management.commands.createsuperuser import Command as BaseCommand
from django.core.management import CommandError

class Command(BaseCommand):
    help = 'Create a superuser with email and role'

    def handle(self, *args, **options):
        options.setdefault('interactive', True)
        
        # Get the required fields
        email = options.get('email') or input('Email: ')
        role = options.get('role') or input('Role (admin): ') or 'admin'
        
        # Validate role
        if role.lower() not in [choice[0] for choice in self.UserModel.ROLE_CHOICES]:
            raise CommandError(f"Invalid role. Must be one of: {[choice[0] for choice in self.UserModel.ROLE_CHOICES]}")
        
        # Create the user data
        user_data = {
            'email': email,
            'role': role.lower(),
            'is_staff': True,
            'is_superuser': True,
            'is_active': True,
            'is_verified': True
        }
        
        # Get password if not provided
        password = None
        if options.get('interactive'):
            password = self.get_password()
        else:
            password = options.get('password')
            if not password:
                raise CommandError("Must provide --password in non-interactive mode")
        
        # Create the user
        self.UserModel._default_manager.create_superuser(**user_data, password=password)
        self.stdout.write(self.style.SUCCESS('Superuser created successfully.'))
    
    def get_password(self):
        from getpass import getpass
        password = getpass('Password: ')
        password2 = getpass('Password (again): ')
        if password != password2:
            raise CommandError("Error: Your passwords didn't match.")
        if not password:
            raise CommandError("Error: Blank passwords aren't allowed.")
        return password