# Estágio de construção (Build Stage)
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build

# Define o diretório de trabalho dentro do contêiner Docker para o estágio de construção.
WORKDIR /app

# Copia o arquivo pom.xml primeiro para que o Docker possa usar o o cache de camada.
# Se o pom.xml não mudar, o Maven não precisa baixar as dependências novamente.
COPY pom.xml .

# Baixa as dependências do projeto.
# 'dependency:go-offline' é útil para garantir que todas as dependências transitivas são resolvidas.
RUN mvn dependency:go-offline

# Copia o restante do código-fonte da aplicação para o diretório de trabalho.
COPY src ./src

# Compila o projeto Spring Boot e empacota-o em um JAR executável.
# O flag '-DskipTests' é adicionado para PULAR a execução dos testes durante a construção da imagem Docker.
RUN mvn clean install -DskipTests

# Estágio de execução (Runtime Stage)
# Usa uma imagem base leve com apenas o Java Runtime Environment (JRE).
# 'eclipse-temurin:21-jre-alpine' fornece o JRE 21 em uma base Alpine, ideal para execução de aplicativos.
FROM eclipse-temurin:21-jre-alpine

# Define o diretório de trabalho para o estágio de execução.
WORKDIR /app

# Copia o JAR executável gerado no estágio de construção para o estágio de execução.
# O nome do JAR é <artifactId>-<version>.jar, que é "tarefasonline-0.0.1-SNAPSHOT.jar"
# Renomeamos para 'app.jar' dentro do contêiner para simplificar.
COPY --from=build /app/target/tarefasonline-0.0.1-SNAPSHOT.jar app.jar
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ESTA LINHA ESTÁ CORRETA PARA SEU POM.XML ATUAL

# Expõe a porta que a aplicação Spring Boot usará (padrão 8081 para este frontend).
EXPOSE 8081

# Define o comando que será executado quando o contêiner Docker for iniciado.
# Este comando inicia sua aplicação Spring Boot.
ENTRYPOINT ["java", "-jar", "app.jar"]

# --- Dicas Importantes para o Deploy no Render.com ---
# 1. Ajuste a porta: Certifique-se de que o 'server.port' no seu application.properties
#    deste projeto frontend é a mesma porta exposta aqui (8081).
# 2. Variáveis de Ambiente no Render:
#    Você PRECISARÁ configurar a variável de ambiente 'api.base.url' no Render.com.
#    Esta variável deve apontar para a URL pública da sua API de tarefas (backend) já deployada.
#    Exemplo: api.base.url=https://sua-api-de-tarefas.render.com/api
#    NUNCA coloque essa URL diretamente no Dockerfile.
