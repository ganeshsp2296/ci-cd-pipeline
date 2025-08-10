pipeline {
    agent any

    environment {
        MVN_HOME = tool name: 'maven'
        SONAR_SCANNER_HOME = tool name: 'sonar-scanner'
        NEXUS_CRED = credentials('nexus-cred')
        DOCKER_IMAGE = "localhost:30800/docker-hosted-repo/ci-cd-app"
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'ganesh.developer',
                    url: 'https://github.com/ganeshsp2296/ci-cd-pipeline.git',
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

        stage('Build for Sonar') {
            steps {
                sh "${MVN_HOME}/bin/mvn clean compile"
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner"
                }
            }
        }

        stage('Build Artifact') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh "${MVN_HOME}/bin/mvn clean package"
            }
        }

        stage('Upload Artifact to Nexus') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh "${MVN_HOME}/bin/mvn deploy"
            }
        }

        stage('Build Docker Image') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${TIMESTAMP} ."
            }
        }

        stage('Push Docker Image to Nexus') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh "docker push ${DOCKER_IMAGE}:${TIMESTAMP}"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
