pipeline {
    agent any

    tools {
        maven 'maven' // Jenkins-managed Maven (configured in Global Tool Configuration)
    }

    environment {
        scannerHome = tool name: 'sonar-scanner' // Jenkins-managed SonarQube Scanner
        NEXUS_CRED = credentials('nexus-cred')
        DOCKER_IMAGE = "nexus.yourdomain.com/docker-hosted-repo/your-app"
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'ganesh.developer', url: 'https://github.com/ganeshsp2296/ci-cd-pipeline.git'
            }
        }

        stage('Setup Maven Settings') {
            steps {
                sh '''
                    mkdir -p /var/lib/jenkins/.m2
                    cp mvn-app/settings.xml /var/lib/jenkins/.m2/settings.xml
                    chown -R jenkins:jenkins /var/lib/jenkins/.m2
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh "${scannerHome}/bin/sonar-scanner"
                }
            }
        }

        stage('Build Artifact') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                sh 'mvn deploy'
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
