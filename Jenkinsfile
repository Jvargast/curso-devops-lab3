def tagAndPush(String localImage, String repo, String registry, String credentialId) {
    docker.withRegistry(registry, credentialId) {
        sh """
            docker tag ${localImage} ${repo}:latest
            docker tag ${localImage} ${repo}:${env.APP_SEMANTIC_VERSION}
            docker tag ${localImage} ${repo}:${env.BUILD_NUMBER}

            docker push ${repo}:latest
            docker push ${repo}:${env.APP_SEMANTIC_VERSION}
            docker push ${repo}:${env.BUILD_NUMBER}
        """
    }
}

pipeline {
    agent any

    environment {
        IMAGE_NAME = 'curso-devops-lab3'
        DH_REPO    = 'jvargast/curso-devops-lab3'
        GHCR_REPO  = 'ghcr.io/jvargast/curso-devops-lab3'

        K8S_NAMESPACE  = 'jvargas'
        K8S_DEPLOYMENT = 'curso-devops-lab3'
        K8S_CONTAINER  = 'app'
    }

    stages {
        stage('Version') {
            agent {
                docker {
                    image 'node:24-slim'
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
                    echo "Build number: ${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Dependencias') {
            agent {
                docker {
                    image 'node:24-slim'
                    reuseNode true
                }
            }
            steps {
                sh 'npm ci'
            }
        }

        stage('Tests con cobertura') {
            agent {
                docker {
                    image 'node:24-slim'
                    reuseNode true
                }
            }
            steps {
                sh 'npm run test:cov'
            }
        }

        stage('SonarQube') {
            agent {
                docker {
                    image 'sonarsource/sonar-scanner-cli:latest'
                    args "--entrypoint='' --network lab3-net -e SONAR_SCANNER_OPTS=-Xmx512m"
                    reuseNode true
                }
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh "sonar-scanner -Dsonar.projectVersion=${env.APP_SEMANTIC_VERSION} -Dsonar.javascript.node.maxspace=1024"
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build app') {
            agent {
                docker {
                    image 'node:24-slim'
                    reuseNode true
                }
            }
            steps {
                sh 'npm run build'
            }
        }

        stage('Build Docker image') {
            steps {
                sh "docker build -t ${env.IMAGE_NAME}:local ."
            }
        }

        stage('Push Docker Hub') {
            steps {
                script {
                    tagAndPush(
                        "${env.IMAGE_NAME}:local",
                        env.DH_REPO,
                        'https://index.docker.io/v1/',
                        'credencial-dh'
                    )
                }
            }
        }

        stage('Push GHCR') {
            steps {
                script {
                    tagAndPush(
                        "${env.IMAGE_NAME}:local",
                        env.GHCR_REPO,
                        'https://ghcr.io',
                        'credencial-gh'
                    )
                }
            }
        }
    }
    stage('Update Kubernetes image') {
        agent {
            docker {
                image 'bitnami/kubectl:latest'
                args '--network lab3-net'
                reuseNode true
            }
        }
        steps {
            withKubeConfig([credentialsId: 'credencial-k8']) {
                sh """
                kubectl -n ${env.K8S_NAMESPACE} set image deployment/${env.K8S_DEPLOYMENT} ${env.K8S_CONTAINER}=${env.GHCR_REPO}:${env.BUILD_NUMBER}
                kubectl -n ${env.K8S_NAMESPACE} rollout status deployment/${env.K8S_DEPLOYMENT}
            """
            }
        }
    }
}
