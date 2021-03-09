FROM python:3.6.0-alpine

RUN apk --no-cache update \
&& apk add --no-cache python py3-pip \
&& rm -rf /var/cache/apk/*

WORKDIR /app
COPY . /app

RUN apk --no-cache --update add build-base && \
    pip install --no-cache-dir -r /app/requirements.txt && \
    apk del build-base

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

CMD ["python3", "post_app.py"]
