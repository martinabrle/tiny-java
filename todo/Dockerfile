# build using "docker build ./ -t tiny-java --build-arg VERSION=1.2.3.4"
# run using docker run -p 8080:8080 docker.io/library/tiny-java -e SPRING_PROFILES_ACTIVE=local

# build stage
FROM openjdk:11-jdk as build

VOLUME /tmp
WORKDIR /
ADD . .

ENV SPRING_PROFILES_ACTIVE=local
ENV JAVA_OPTS=-Dspring.profiles.active=local

RUN ./mvnw clean package

RUN mv ./target/todo-*.jar "./target/todo-app.jar"

# package stage
FROM openjdk:11-jdk

ARG VERSION

WORKDIR /

COPY --from=build ../target/todo-app.jar /

# "-Dspring.profiles.active=local" , 

ENV VERSION="${VERSION}"

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/todo-app.jar" ]