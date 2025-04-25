pipeline {
  agent any
  environment {
    DOCKERHUB_USER = "rasken2003"
    BUILD_HOST = "root@172.19.0.1:2226"
    PROD_HOST = "root@172.19.0.1:2227"
    BUILD_TIMESTAMP = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
  }
  stages {
    stage('Pre Check') {
      steps {
        sh "test -f ~/.docker/config.json"
        sh "cat ~/.docker/config.json | grep docker.io"
      }
    }
    stage('Build') {
      steps {
        sh "cat docker-compose.build.yml"
        sh "DOCKER_HOST=ssh://${BUILD_HOST} docker compose -f docker-compose.build.yml down"
        sh "docker -H ssh://${BUILD_HOST} volume prune -f"
        sh "DOCKER_HOST=ssh://${BUILD_HOST} docker compose -f docker-compose.build.yml build"
        sh "DOCKER_HOST=ssh://${BUILD_HOST} docker compose -f docker-compose.build.yml up -d"
        sh "./wait-for-it.sh ${BUILD_HOST%} --timeout=30 -- echo 'SSHホスト到達OK'"
        sh "docker -H ssh://${BUILD_HOST} exec dockerkvs_apptest /usr/local/bin/wait-for-it.sh app:80 --timeout=30 -- echo 'app is ready!'"
        sh "DOCKER_HOST=ssh://${BUILD_HOST} docker compose -f docker-compose.build.yml ps"
      }
    }
    stage('Test') {
      steps {
        sh "docker -H ssh://${BUILD_HOST} container exec dockerkvs_apptest pytest -v test_app.py"
        sh "docker -H ssh://${BUILD_HOST} container exec dockerkvs_webtest pytest -v test_static.py"
        sh "docker -H ssh://${BUILD_HOST} container exec dockerkvs_webtest pytest -v test_selenium.py"
        sh "DOCKER_HOST=ssh://${BUILD_HOST} docker compose -f docker-compose.build.yml down"
      }
    }
    stage('Register') {
      steps {
        sh "docker -H ssh://${BUILD_HOST} tag dockerkvs_web ${DOCKERHUB_USER}/dockerkvs_web:${BUILD_TIMESTAMP}"
        sh "docker -H ssh://${BUILD_HOST} tag dockerkvs_app ${DOCKERHUB_USER}/dockerkvs_app:${BUILD_TIMESTAMP}"
        sh "docker -H ssh://${BUILD_HOST} push ${DOCKERHUB_USER}/dockerkvs_web:${BUILD_TIMESTAMP}"
        sh "docker -H ssh://${BUILD_HOST} push ${DOCKERHUB_USER}/dockerkvs_app:${BUILD_TIMESTAMP}"
      }
    }
    stage('Deploy') {
      steps {
        sh "cat docker-compose.prod.yml"
        sh "echo 'DOCKERHUB_USER=${DOCKERHUB_USER}' > .env"
        sh "echo 'BUILD_TIMESTAMP=${BUILD_TIMESTAMP}' >> .env"
        sh "echo 'WEB_PORT=8082' >> .env"
        sh "cat .env"
        sh "DOCKER_HOST=ssh://${PROD_HOST} docker compose -f docker-compose.prod.yml up -d"
        sh "DOCKER_HOST=ssh://${PROD_HOST} docker compose -f docker-compose.prod.yml ps"
      }
    }
  }
}