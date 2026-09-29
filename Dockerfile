## build stage ##
FROM eclipse-temurin:17-jdk-noble AS build

ARG SERVICE

WORKDIR /build

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY $SERVICE/pom.xml $SERVICE/pom.xml
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -f $SERVICE/pom.xml

COPY $SERVICE/src $SERVICE/src
RUN ./mvnw package -f $SERVICE/pom.xml

## run stage ##
FROM eclipse-temurin:17-jre-noble

ARG SERVICE

WORKDIR /run

COPY --from=build /build/$SERVICE/target/*.jar app.jar
RUN adduser --disabled-password --gecos "" run
RUN chown -R run:run .
RUN chmod 700 .

USER run

CMD ["java", "-jar", "app.jar"]
