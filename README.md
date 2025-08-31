hack-a-milli

App-Developer Challenge



Skillproof - App Developer Challenge

Skillproof is a transformative platform that bridges the skills gap for Kenyan students and recent graduates by connecting them with real-world challenges from leading companies across government, private, and public sectors. It empowers students to gain practical experience, build verifiable digital portfolios, and enhance employability while enabling companies to source innovative solutions and talent efficiently.



Project Overview

Skillproof fosters collaboration between students, educational institutions, and employers to address Kenya’s skills mismatch and youth unemployment. Students engage with challenges via a mobile app (Android, iOS in development), earning points, feedback, and digital tokens. Companies use a web portal to post challenges, review submissions, and identify talent. The platform leverages a modern tech stack to deliver a seamless, scalable experience.



Repository Structure

/mobile-app: Contains the Flutter/Dart mobile application for students.

/web-app: Contains the Next.js/React frontend and Django backend for the company web portal.

/releases: Contains the Android APK file (SkillProof.apk) for the mobile app.



Technology Stack

Frontend (Web): Next.js, React, Tailwind CSS, Framer Motion

Frontend (Mobile): Flutter, Dart

Backend: Python, Django, Django REST Framework

API Client: Axios

Storage: LocalStorage for token and user data

Database: PostgreSQL

Web Server: Nginx

Cloud Platform: Microsoft Azure

Operating System: Windows Server

SSL/TLS: Certbot (Let’s Encrypt), ACME Protocol

Domain Registrar: HostPinnacle



Setup and Usage

Prerequisites

Mobile App:

Flutter SDK (v3.0 or higher)

Dart (v2.12 or higher)

Android Studio or Xcode (for iOS development)



Web App:

Node.js (v16 or higher)

Python (v3.8 or higher)

PostgreSQL (v13 or higher)

Nginx (v1.18 or higher)



General:

Git

Microsoft Azure account (for deployment)

Certbot (for SSL setup)



Mobile App Setup

Clone the Repository:

git clone https://github.com/enricoshilisia-cmd/hack-a-milli.git

cd hack-a-milli/mobile-app



Install Dependencies:

flutter pub get



Configure Environment:

Update lib/.env with API endpoint\[](https://api.skillproof.me.ke) and other environment variables.

Ensure an Android emulator or device is connected.



Run the App:

flutter run



Build APK:

flutter build apk --release

The APK will be generated in build/app/outputs/flutter-apk/app-release.apk.



Web App Setup

Navigate to Web App:

cd hack-a-milli/web-app



Frontend (Next.js):

Install dependencies:cd frontend

npm install

Configure environment variables in .env.local (e.g., API\_URL=https://api.skillproof.me.ke).

Run the development server:npm run dev



Backend (Django):

Install dependencies:cd backend

pip install -r requirements.txt

Configure PostgreSQL in settings.py and apply migrations:python manage.py migrate

Run the server:python manage.py runserver



Nginx and SSL Setup:

Install Nginx on the Windows Server VM.

Copy the provided Nginx configuration to nginx.conf (see deployment details).

Use Certbot to obtain SSL certificates:certbot certonly --webroot -w /path/to/acme-challenges -d skillproof.me.ke -d www.skillproof.me.ke -d api.skillproof.me.ke

Restart Nginx to apply changes.



Deployment

Azure Setup:

Deploy the Windows Server VM in Azure.

Configure DNS records in Azure to map to HostPinnacle’s nameservers.

Set up Nginx to route traffic to Next.js (port 3000) and Django (port 8000).



Domain:

Registered via HostPinnacle (skillproof.me.ke).

Subdomain api.skillproof.me.ke used for mobile app API access.



APK:

The Android APK is available in the /releases folder or at https://skillproof.me.ke/downloads/SkillProof.apk.



Usage

Students:

Download the Android app or APK from /releases.

Sign up, browse challenges, submit solutions, and track progress via the mobile app.

Build a verifiable portfolio with earned points and feedback.



Companies:

Access the web portal at https://skillproof.me.ke.

Post challenges, review submissions, and use analytics to identify talent.



Contributing

Contributions are welcome! Please submit a pull request or open an issue to discuss improvements.



License

MIT License

