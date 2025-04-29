# Django Web App for Viewing QC and SARTools Reports
This guide aims to walk through the steps for building a lightweight Django app to:
+ Upload and store project-linked QC/SARTools reports
+ Search by project name
+ View embedded HTML reports in-browser

## Requirements
1. Python
2. Django
3. SQLite or other SQL system
4. Conda (for future functionality)

## Install
You may wish to modify conda to use additional requriements for further functionality.

```
conda create --name webenv python=3.7
conda activate webenv
pip install django
```

## Start a Django project
Django comes with an automated command to setup a base web environment.

```
django-admin startproject projectviewer
cd projectviewer
python manage.py startapp reports
```

## Modify settings
You'll want to add a few elements to your settings first, including the name of this tool:

in ***projectviewer/settings.py*** modify...
```
import os
from pathlib import Path  # <-- This is added

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = Path(__file__).resolve().parent.parent  # <-- This is changed


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/2.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = '#####'
# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = []


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'reports', # <-- This is added
]
```
Then later on in the same file...
```
STATIC_URL = '/static/'
MEDIA_URL = '/media/'  # <-- This is added
MEDIA_ROOT = BASE_DIR / 'media'  # <-- This is added

```

## Define the Model
Now we need to make the python script that will actually help serve the right files.

in ***reports/models.py***
```
from django.db import models

class ProjectReport(models.Model):
    project_name = models.CharField(max_length=100, unique=True)
    qc_report = models.FileField(upload_to='qc_reports/')
    sartools_report = models.FileField(upload_to='sartools_reports/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.project_name
```

## Create the Forms
We'll lalso want to genrate the forms for lookup. You'll actually need to create this, not just modify.

in ***reports/forms.py***
```
from django import forms
from .models import ProjectReport

class ReportUploadForm(forms.ModelForm):
    class Meta:
        model = ProjectReport
        fields = ['project_name', 'qc_report', 'sartools_report']
```

you should also create the view

in ***reports/views.py***
```
from django.shortcuts import render, get_object_or_404
from .forms import ReportUploadForm
from .models import ProjectReport

def upload_report(request):
    if request.method == 'POST':
        form = ReportUploadForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
    else:
        form = ReportUploadForm()
    return render(request, 'upload.html', {'form': form})

def view_report(request):
    query = request.GET.get('q')
    report = None
    if query:
        try:
            report = ProjectReport.objects.get(project_name=query)
        except ProjectReport.DoesNotExist:
            report = None
    return render(request, 'search.html', {'report': report})
```

## Genrate URLs
We now actually need to describe what the url will look like.

in ***reports/urls.py*** you'll need to create this one too.
```
from django.urls import path
from django.views.generic import RedirectView
from . import views

urlpatterns = [
    path('', RedirectView.as_view(url='search/', permanent=False)),
    path('upload/', views.upload_report, name='upload_report'),
    path('search/', views.view_report, name='view_report'),
]
```

Then in ***projectviewer/urls.py***
```
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('reports.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

## Make htmls
We can modify how it looks now
First the upload

in ***reports/templates/upload.html***
```
<h2>Upload Project Reports</h2>
<form method="post" enctype="multipart/form-data">
    {% csrf_token %}
    {{ form.as_p }}
    <input type="submit" value="Upload">
</form>
```

Then the search
in ***reports/templates/search.html***
```
<h2>Search Project Reports</h2>
<form method="get">
    <input type="text" name="q" placeholder="Enter project name">
    <button type="submit">Search</button>
</form>

{% if report %}
  <h3>QC Report</h3>
  <iframe src="{{ report.qc_report.url }}" width="100%" height="600px"></iframe>

  <h3>SARTools Report</h3>
  <iframe src="{{ report.sartools_report.url }}" width="100%" height="600px"></iframe>
{% elif request.GET.q %}
  <p>No report found for "{{ request.GET.q }}"</p>
{% endif %}
```

## Final stages
We need Django to process whats been coded and then run the server `python manage.py makemigrations`
Which should create an output like this:
```
Migrations for 'reports':
  reports/migrations/0001_initial.py
    - Create model ProjectReport
```
Then we need to run the migration `python manage.py migrate`
Which should create an output like this:
```
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, reports, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying admin.0002_logentry_remove_auto_add... OK
  Applying admin.0003_logentry_add_action_flag_choices... OK
  Applying contenttypes.0002_remove_content_type_name... OK
  Applying auth.0002_alter_permission_name_max_length... OK
  Applying auth.0003_alter_user_email_max_length... OK
  Applying auth.0004_alter_user_username_opts... OK
  Applying auth.0005_alter_user_last_login_null... OK
  Applying auth.0006_require_contenttypes_0002... OK
  Applying auth.0007_alter_validators_add_error_messages... OK
  Applying auth.0008_alter_user_username_max_length... OK
  Applying auth.0009_alter_user_last_name_max_length... OK
  Applying auth.0010_alter_group_name_max_length... OK
  Applying auth.0011_update_proxy_permissions... OK
  Applying reports.0001_initial... OK
  Applying sessions.0001_initial... OK
```
Finally lets view our website like this: `python manage.py runserver`
Generating a console log like this:
```
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).
April 29, 2025 - 14:29:44
Django version 2.2.14, using settings 'projectviewer.settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.
```

## Extra steps
This generates a just the framework, no pretty layout, to do include
+ tabs to switch between search and upload.
+ setup a SQL to import to
+ setup security (passwords/admin
+ setup django tests

## 1. Tabs for Navigation
For this we'll define a base.html to add to in ***reports/templates/base.html***
```
<!-- templates/base.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{% block title %}Project Viewer{% endblock %}</title>
</head>
<body>
    <nav>
        <a href="{% url 'upload_report' %}">Upload Report</a> |
        <a href="{% url 'view_report' %}">Search Reports</a>
    </nav>
    <hr>
    {% block content %}{% endblock %}
</body>
</html>
```

Now we need to modify ***reports/templates/search.html*** and ***reports/templates/upload.html***
we will add right at the beginning to load base.html
```
{% extends 'base.html' %}
{% block content %}
```
and then right at the end
```
{% endblock %}
```

## 2. SQLite3 Database 
(though other SQL dbs could be used)
This should be already setup but empty. We should look to import some test data

## 3. Admin and Authentication
As this could involve sensitive data we want to lock data behind a password.

to ***reports/admin.py*** add:
```
from django.contrib import admin

from django.contrib import admin
from django.shortcuts import render

from .models import ProjectReport
admin.site.register(ProjcetReport)

```
You should add to ***projectviewer/settings.py*** `LOGIN_URL = '/admin/login/'`

Then we need to create a user. start with `python manage.py createsuperuser`
```
