pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'maven'
        SONAR_SCANNER_HOME = tool 'sonar-scanner'
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Get Public IP') {
            steps {
                script {
                    env.PUBLIC_IP = sh(script: "curl -s http://checkip.amazonaws.com", returnStdout: true).trim()
                    env.NEXUS_URL = "http://${env.PUBLIC_IP}:8081"
                    env.DOCKER_REGISTRY = "${env.PUBLIC_IP}:30800"
                    env.SONAR_URL = "http://${env.PUBLIC_IP}:9000"
                    echo "Public IP: ${env.PUBLIC_IP}"
                    echo "Nexus URL: ${env.NEXUS_URL}"
                    echo "Docker Registry: ${env.DOCKER_REGISTRY}"
                    echo "SonarQube URL: ${env.SONAR_URL}"
                }
            }
        }

        stage('Checkout') {
            steps {
                git url: 'https://github.com/ganeshsp2296/ci-cd-pipeline.git',
                    branch: 'ganesh.developer',
                    credentialsId: 'Github-token'
            }
        }

        stage('Copy settings.xml') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh """
                        mkdir -p /var/lib/jenkins/.m2
                        sed -e 's|__NEXUS_URL__|${NEXUS_URL}|g' \
                            -e 's|__NEXUS_USERNAME__|${NEXUS_USERNAME}|g' \
                            -e 's|__NEXUS_PASSWORD__|${NEXUS_PASSWORD}|g' \
                            mvn-app/settings.xml > /var/lib/jenkins/.m2/settings.xml
                        chown jenkins:jenkins /var/lib/jenkins/.m2/settings.xml
                    """
                }
            }
        }

        stage('Build Artifact') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    dir('mvn-app') {
                        sh """
                            ${MAVEN_HOME}/bin/mvn clean package deploy \
                                -DskipTests \
                                -DNEXUS_URL=${env.NEXUS_URL} \
                                -DNEXUS_USERNAME=${NEXUS_USERNAME} \
                                -DNEXUS_PASSWORD=${NEXUS_PASSWORD}
                        """
                    }
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    dir('mvn-app') {
                        sh """
                            ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                                -Dsonar.projectBaseDir=. \
                                -Dsonar.host.url=${env.SONAR_URL} \
                                -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.DOCKER_IMAGE = "${DOCKER_REGISTRY}/docker-hosted-repo/ci-cd-app"
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${TIMESTAMP} .
                        docker tag ${DOCKER_IMAGE}:${TIMESTAMP} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "$PASSWORD" | docker login ${DOCKER_REGISTRY} -u "$USERNAME" --password-stdin
                        docker push ${DOCKER_IMAGE}:${TIMESTAMP}
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'mvn-app/target/*.jar', fingerprint: true
        }
        always {
            cleanWs()
        }
    }
}
