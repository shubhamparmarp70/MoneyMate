FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY moneymanager/pom.xml .
COPY moneymanager/src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app/target/*.jar moneymanager-v1.0.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "moneymanager-v1.0.jar"]