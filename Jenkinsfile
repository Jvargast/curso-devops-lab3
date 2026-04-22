pipeline {
    agent any

    environment {
        IMAGE_NAME = "curso-devops-lab3"
    }

    stages {
        stage("Version") {
            agent {
                docker {
                    image "node:24"
                    reuseNode true
                }
            }
            steps {
                script {
                    env.APP_SEMANTIC_VERSION = sh(
                        script: "node -p \"require('./package.json').version\"",
                        returnStdout: true
                    ).trim()
                    echo "Version detectada: ${env.APP_SEMANTIC_VERSION}"
                }
            }
        }

        stage("Dependencias") {
            agent {
                docker {
                    image "node:24"
                    reuseNode true
                }
            }
            steps {
                sh "npm ci"
            }
        }

        stage("Tests con cobertura") {
            agent {
                docker {
                    image "node:24"
                    reuseNode true
                }
            }
            steps {
                sh "npm run test:cov"
            }
        }

        stage("SonarQube") {
            agent {
                docker {
                    image "sonarsource/sonar-scanner-cli:latest"
                    reuseNode true
                }
            }
            steps {
                withSonarQubeEnv("sonarqube") {
                    sh "sonar-scanner -Dsonar.projectVersion=${env.APP_SEMANTIC_VERSION}"
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Build app") {
            agent {
                docker {
                    image "node:24"
                    reuseNode true
                }
            }
            steps {
                sh "npm run build"
            }
        }

        stage("Build Docker image") {
            steps {
                sh "docker build -t ${env.IMAGE_NAME}:local ."
            }
        }
    }
}