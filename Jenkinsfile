pipeline {
    agent any

    environment {
        SONAR_SCANNER_HOME = tool name: 'SonarQube Scanner'
        MVN_HOME = tool name: 'Maven'
        NEXUS_CRED = credentials('nexus-cred')
        DOCKER_IMAGE = "nexus.yourdomain.com/docker-hosted-repo/your-app"
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'ganesh.developer', url: 'https://github.com/ganeshsp2296/your-repo.git'
            }
        }

        stage('Copy settings.xml') {
            steps {
                sh '''
                    mkdir -p /var/lib/jenkins/.m2
                    cp settings.xml /var/lib/jenkins/.m2/settings.xml
                    chown jenkins:jenkins /var/lib/jenkins/.m2/settings.xml
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner"
                }
            }
        }

        stage('Build Artifact') {
            steps {
                sh "${MVN_HOME}/bin/mvn clean package -DskipTests"
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                sh "${MVN_HOME}/bin/mvn deploy"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t $DOCKER_IMAGE:$TIMESTAMP .
                    docker tag $DOCKER_IMAGE:$TIMESTAMP $DOCKER_IMAGE:latest
                '''
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        echo "$PASSWORD" | docker login nexus.yourdomain.com -u "$USERNAME" --password-stdin
                        docker push $DOCKER_IMAGE:$TIMESTAMP
                        docker push $DOCKER_IMAGE:latest
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}

