FROM aperrin66/geospaas:0.0.1-slim
LABEL purpose="Environment for REST API for Django-Geo-SpaaS"

# Install Django-rest-framework
RUN apt update && \
    apt install -y git && \
    apt clean && rm -rf /var/lib/apt/lists/* && \
    pip install --upgrade --no-cache-dir \
    'celery==5.2.*' \
    'django-celery-results==2.2.*' \
    django-filter \
    djangorestframework \
    djangorestframework-filters==1.0.0dev2 \
    markdown

WORKDIR /src
