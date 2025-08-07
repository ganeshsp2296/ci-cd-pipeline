pipeline {
    agent any

    environment {
        MVN_HOME = tool name: 'maven3'
        NEXUS_CRED = credentials('nexus-cred')
        DOCKER_IMAGE = "localhost:30800/docker-hosted-repo/ci-cd-app"
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/ganeshsp2296/ci-cd-pipeline.git', branch: 'ganesh.developer', credentialsId: 'Github-token'
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

        stage('SonarQube Scan') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner"
                    }
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
                        echo "$PASSWORD" | docker login localhost:30800 -u "$USERNAME" --password-stdin
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

