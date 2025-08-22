FROM openjdk:17-jdk-slim
WORKDIR /app
COPY mvn-app/target/ganesh-app-1.0-SNAPSHOT.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]

