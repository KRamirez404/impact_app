FROM ghcr.io/cirruslabs/flutter:stable
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --dart-define=API_BASE_URL=http://localhost:5000/api
EXPOSE 8080
CMD ["flutter", "run", "-d", "web-server", \
     "--web-port=8080", \
     "--web-hostname=0.0.0.0", \
     "--dart-define=API_BASE_URL=http://localhost:5000/api"]

