FROM maven:3.8.4-openjdk-17 AS build

WORKDIR /app

COPY ./pom.xml ./project/
COPY ./src ./project/src

RUN mvn -f ./project clean package -DskipTests

FROM openjdk:17

WORKDIR /app

COPY --from=build /app/project/target/*.jar /app/*.jar

CMD ["java", "-jar", "/app/*.jar"]
