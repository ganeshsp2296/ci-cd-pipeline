pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'maven'
        SONAR_SCANNER_HOME = tool 'sonar-scanner'
        NEXUS_CRED = credentials('nexus-cred')
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
        DOCKER_IMAGE_NAME = "ci-cd-app"
    }

    stages {
        stage('Fetch Public IP') {
            steps {
                script {
                    PUBLIC_IP = sh(script: "curl -s ifconfig.me", returnStdout: true).trim()
                    echo "Public IP: ${PUBLIC_IP}"
                    DOCKER_REGISTRY = "${PUBLIC_IP}:30800/docker-hosted-repo"
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
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    dir('mvn-app') {
                        sh "${MAVEN_HOME}/bin/mvn clean package -DskipTests"
                    }
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    dir('mvn-app') {
                        withSonarQubeEnv('sonarqube') {
                            sh """
                                ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                                -Dsonar.projectKey=ci-cd-app \
                                -Dsonar.host.url=http://${PUBLIC_IP}:9000 \
                                -Dsonar.login=sonarqube-token \
                                -Dproject.settings=sonar-project.properties
                            """
                        }
                    }
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            when {
                expression { currentBuild.currentResult == 'SUCCESS' }
            }
            steps {
                dir('mvn-app') {
                    sh "${MAVEN_HOME}/bin/mvn deploy"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${TIMESTAMP} .
                    docker tag ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${TIMESTAMP} ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest
                """
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "$PASSWORD" | docker login http://${PUBLIC_IP}:30800 -u "$USERNAME" --password-stdin
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${TIMESTAMP}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest
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
