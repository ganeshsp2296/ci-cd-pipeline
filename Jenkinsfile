pipeline {
    agent any
    environment {
        SONAR_URL = 'http://sonarqube.default.svc.cluster.local:9000'
        SONAR_TOKEN = credentials('sonar-token')
        NEXUS_URL = 'http://nexus.default.svc.cluster.local:8081'
        IMAGE_NAME = "ganesh-app"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'ganesh.developer', url: 'https://github.com/ganeshsp2296/ci-cd-pipeline.git'
            }
        }
        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('MySonarQube') {
                    sh 'mvn clean verify sonar:sonar'
                }
            }
        }
        stage('Build Artifact') {
            steps {
                script {
                    env.BUILD_ID = sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim()
                }
                sh "mvn package"
                sh "cp target/*.jar target/app-${BUILD_ID}.jar"
            }
        }
        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh '''
                    curl -v -u $NEXUS_USER:$NEXUS_PASS --upload-file target/app-${BUILD_ID}.jar \
                    ${NEXUS_URL}/repository/maven-releases/com/example/ganesh-app/${BUILD_ID}/ganesh-app-${BUILD_ID}.jar
                    '''
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:${BUILD_ID}")
                }
            }
        }
        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    script {
                        sh "docker tag ${IMAGE_NAME}:${BUILD_ID} nexus.default.svc.cluster.local:8082/${IMAGE_NAME}:${BUILD_ID}"
                        sh "docker login nexus.default.svc.cluster.local:8082 -u $NEXUS_USER -p $NEXUS_PASS"
                        sh "docker push nexus.default.svc.cluster.local:8082/${IMAGE_NAME}:${BUILD_ID}"
                    }
                }
            }
        }
    }
}

