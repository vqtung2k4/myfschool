# Stage 1: Build the Flutter Web app
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app
# Optimization: Copy pubspec first to cache dependencies
COPY pubspec.* . 
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
# Copy the build output to the default Nginx html location
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
# Fixed the typo here: "nginx" instead of "ngnix"
CMD ["nginx", "-g", "daemon off;"]