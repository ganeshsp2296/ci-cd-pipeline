pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'maven'                   // your configured Maven tool name in Jenkins
        SONAR_SCANNER_HOME = tool 'sonar-scanner'  // your configured Sonar Scanner tool name
        NEXUS_CRED = credentials('nexus-cred')     // your Nexus credentials ID in Jenkins
        DOCKER_IMAGE = "172.31.10.224:30800/docker-hosted-repo/ci-cd-app"
        TIMESTAMP = new Date().format("yyyyMMdd-HHmm", TimeZone.getTimeZone('IST'))
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Copy settings.xml') {
            steps {
                sh '''
                    mkdir -p ~/.m2
                    cp mvn-app/settings.xml ~/.m2/settings.xml
                '''
            }
        }

        stage('Build for Sonar') {
            steps {
                dir('mvn-app') {
                    sh "${MAVEN_HOME}/bin/mvn clean compile"
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('mvn-app') {
                    withSonarQubeEnv('sonarqube') {
                        sh """
                          ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                            -Dproject.settings=sonar-project.properties \
                            -Dsonar.projectVersion=${BUILD_NUMBER}
                        """
                    }
                }
            }
        }

        stage('Build Artifact') {
            steps {
                dir('mvn-app') {
                    sh "${MAVEN_HOME}/bin/mvn clean package -DskipTests"
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                dir('mvn-app') {
                    sh "${MAVEN_HOME}/bin/mvn deploy"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${TIMESTAMP} .
                    docker tag ${DOCKER_IMAGE}:${TIMESTAMP} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    sh """
                        echo $PASSWORD | docker login http://172.31.10.224:30800 -u $USERNAME --password-stdin
                        docker push ${DOCKER_IMAGE}:${TIMESTAMP}
                        docker push ${DOCKER_IMAGE}:latest
                    """
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
