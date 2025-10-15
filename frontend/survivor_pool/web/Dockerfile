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

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
