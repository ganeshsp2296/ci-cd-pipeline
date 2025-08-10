pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'maven'
        SONAR_SCANNER_HOME = tool 'sonar-scanner'
        NEXUS_CRED = credentials('nexus-cred')
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Get Public IP') {
            steps {
                script {
                    PUBLIC_IP = sh(script: "curl -s http://checkip.amazonaws.com", returnStdout: true).trim()
                    NEXUS_URL = "http://${PUBLIC_IP}:8081"
                    DOCKER_REGISTRY = "${PUBLIC_IP}:30800"
                    echo "Public IP: ${PUBLIC_IP}"
                    echo "Nexus URL: ${NEXUS_URL}"
                    echo "Docker Registry: ${DOCKER_REGISTRY}"
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
                sh '''
                    mkdir -p /var/lib/jenkins/.m2
                    cp mvn-app/settings.xml /var/lib/jenkins/.m2/settings.xml
                    chown jenkins:jenkins /var/lib/jenkins/.m2/settings.xml
                '''
            }
        }

        stage('Build Artifact') {
            steps {
                dir('mvn-app') {
                    sh "${MAVEN_HOME}/bin/mvn clean package -DskipTests -DNEXUS_URL=${NEXUS_URL}"
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('mvn-app') {
                    withSonarQubeEnv('sonarqube') {
                        sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner -Dproject.settings=sonar-project.properties"
                    }
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    dir('mvn-app') {
                        sh """
                            ${MAVEN_HOME}/bin/mvn deploy \
                            -DNEXUS_URL=${NEXUS_URL} \
                            -DNEXUS_USERNAME=${NEXUS_USERNAME} \
                            -DNEXUS_PASSWORD=${NEXUS_PASSWORD}
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    DOCKER_IMAGE = "${DOCKER_REGISTRY}/docker-hosted-repo/ci-cd-app"
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
                        echo "$PASSWORD" | docker login http://${DOCKER_REGISTRY} -u "$USERNAME" --password-stdin
                        docker push ${DOCKER_REGISTRY}/docker-hosted-repo/ci-cd-app:${TIMESTAMP}
                        docker push ${DOCKER_REGISTRY}/docker-hosted-repo/ci-cd-app:latest
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
