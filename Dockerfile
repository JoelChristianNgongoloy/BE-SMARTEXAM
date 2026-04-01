# ============================================================
# Stage 1 — Build
# ============================================================
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Cache Maven wrapper & dependencies first
COPY mvnw .
COPY .mvn .mvn
RUN chmod +x mvnw

COPY pom.xml .
RUN ./mvnw dependency:go-offline -B

# Copy source & build
COPY src ./src
RUN ./mvnw clean package -DskipTests -B \
    && mv target/*.jar app.jar

# ============================================================
# Stage 2 — Runtime
# ============================================================
FROM eclipse-temurin:21-jre-alpine AS runtime

# Security: run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy built artifact
COPY --from=build /app/app.jar app.jar

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

# JVM tuning for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/api/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
