FROM ghcr.io/cirruslabs/flutter:3.35.3 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
ARG API_BASE_URL
RUN flutter build web --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:alpine AS runtime

RUN rm /etc/nginx/conf.d/default.conf
COPY web/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

RUN addgroup -S app && adduser -S app -G app \
    && mkdir -p /var/cache/nginx /var/run /run /var/log/nginx \
    && chown -R app:app /var/cache/nginx /var/run /run /var/log/nginx /etc/nginx /usr/share/nginx/html \
    && if grep -q '^user ' /etc/nginx/nginx.conf; then sed -i 's/^user .*/user app;/' /etc/nginx/nginx.conf; else sed -i '1iuser app;' /etc/nginx/nginx.conf; fi

USER app

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
