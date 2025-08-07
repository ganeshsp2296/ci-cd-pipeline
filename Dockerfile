FROM openjdk:17
COPY mvn-app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
