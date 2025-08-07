pipeline {
    agent any

    environment {
        MAVEN_HOME = tool name: 'maven'
        SONAR_SCANNER_HOME = tool name: 'sonar-scanner'
    }

    tools {
        maven 'maven'
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'Github-token', url: 'https://github.com/ganeshsp2296/ci-cd-pipeline.git', branch: 'ganesh.developer'
            }
        }

        stage('Copy settings.xml') {
            steps {
                sh '''
                    mkdir -p /var/lib/jenkins/.m2
                    cp mvn-app/settings.xml /var/lib/jenkins/.m2/settings.xml
                    chown -R jenkins:jenkins /var/lib/jenkins/.m2
                '''
            }
        }

        stage('Build with Maven') {
            steps {
                dir('mvn-app') {
                    sh "${MAVEN_HOME}/bin/mvn clean install"
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    dir('mvn-app') {
                        sh '''
                            ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=ci-cd-app \
                            -Dsonar.projectName=ci-cd-app \
                            -Dsonar.sources=. \
                            -Dsonar.java.binaries=target \
                            -Dsonar.host.url=http://172.31.10.224:30900
                        '''
                    }
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-cred', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    dir('mvn-app') {
                        sh '''
                            ${MAVEN_HOME}/bin/mvn deploy \
                            -DskipTests \
                            -Dnexus.username=$NEXUS_USER \
                            -Dnexus.password=$NEXUS_PASS
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('mvn-app') {
                    sh 'docker build -t ci-cd-app:latest .'
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'NEXUS_CRED', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh '''
                        echo $NEXUS_PASS | docker login -u $NEXUS_USER --password-stdin <your-nexus-host>:<port>
                        docker tag ci-cd-app:latest 172.31.10.224:30800/ci-cd-app:latest
                        docker push 172.31.10.224:30800/ci-cd-app:latest
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
