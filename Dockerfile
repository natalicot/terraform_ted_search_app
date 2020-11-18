FROM maven:3.6.3-jdk-8 AS build
COPY /app /app
WORKDIR app
RUN mvn verify


FROM openjdk:8-jre
COPY --from=build /app/target /target
COPY app/application.properties target/application.properties
WORKDIR target
ENTRYPOINT java -jar embedash-1.1-SNAPSHOT.jar --spring.config.location=./application.properties
 
