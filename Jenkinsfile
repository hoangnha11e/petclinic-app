pipeline {
    agent { label 'build-agent' }
    stages {
        stage('build') {
            steps {
                script {
                    def sharedFiles = [
                        'Dockerfile',
                        'Jenkinsfile',
                        'mvnw',
                        'pom.xml'
                    ]
                    def sharedDirs = [
                        '.mvn'
                    ]
                    def services = [
                        'petclinic-admin-server',
                        'petclinic-api-gateway',
                        'petclinic-config-server',
                        'petclinic-customers-service',
                        'petclinic-discovery-server',
                        'petclinic-genai-service',
                        'petclinic-vets-service',
                        'petclinic-visits-service'
                    ]
                    def toBuild = []
                    if (!env.GIT_PREVIOUS_SUCCESSFUL_COMMIT) {
                        toBuild = services
                    } else {
                        def allChanged = sh(
                            script: "git diff --name-only ${env.GIT_PREVIOUS_SUCCESSFUL_COMMIT} ${env.GIT_COMMIT}",
                            returnStdout: true
                        ).trim().split('\n')
                        def sharedChanged = allChanged.any { c ->
                            sharedFiles.contains(c) || sharedDirs.any { d -> c.startsWith(d + '/') }
                        }
                        if (sharedChanged) {
                            toBuild = services
                        } else {
                            def servicesChanged = services.findAll { s ->
                                allChanged.any { c -> c.startsWith(s + '/') }
                            }
                            toBuild = servicesChanged
                        }
                    }
                    if (toBuild) {
                        //def parallelStages = [:]
                        toBuild.each { s ->
                            //parallelStages[s] = {
                                stage(s) {
                                    def ss = s.replace('petclinic-', '')
                                    withEnv ([
                                        "SERVICE=${s}",
                                        "SERVICE_SHORT=${ss}"
                                    ]) {
                                        withCredentials ([
                                            string (credentialsId: 'IMAGE_REGISTRY', variable: 'IMAGE_REGISTRY'),
                                            string (credentialsId: 'IMAGE_PROJECT', variable: 'IMAGE_PROJECT'),
                                            string (credentialsId: 'IMAGE_USERNAME', variable: 'IMAGE_USERNAME'),
                                            string (credentialsId: 'IMAGE_PASSWORD', variable: 'IMAGE_PASSWORD'),
                                        ]) {
                                            sh '''
                                                trap 'docker logout "$IMAGE_REGISTRY"' EXIT
                                                echo "$IMAGE_PASSWORD" | docker login -u "$IMAGE_USERNAME" --password-stdin "$IMAGE_REGISTRY"
                                                docker build --build-arg "SERVICE=$SERVICE" -t "$IMAGE_REGISTRY/$IMAGE_PROJECT/$SERVICE:$GIT_COMMIT" .
                                                docker push "$IMAGE_REGISTRY/$IMAGE_PROJECT/$SERVICE:$GIT_COMMIT"
                                                docker rmi "$IMAGE_REGISTRY/$IMAGE_PROJECT/$SERVICE:$GIT_COMMIT"
                                                yq -i '.services[strenv(SERVICE_SHORT)].image = strenv(IMAGE_REGISTRY)+"/"+strenv(IMAGE_PROJECT)+"/"+strenv(SERVICE)+":"+strenv(GIT_COMMIT)' /app/jenkins/petclinic/docker-compose.yml
                                            '''
                                        }
                                    }
                                }
                            //}
                        }
                        //parallel parallelStages
                    } else {
                        echo 'No services need to be built.'
                    }
                }
            }
        }
        stage('deploy') {
            steps {
                withCredentials ([
                    string (credentialsId: 'IMAGE_REGISTRY', variable: 'IMAGE_REGISTRY'),
                    string (credentialsId: 'IMAGE_USERNAME', variable: 'IMAGE_USERNAME'),
                    string (credentialsId: 'IMAGE_PASSWORD', variable: 'IMAGE_PASSWORD'),
                    string (credentialsId: 'OPENAI_API_KEY', variable: 'OPENAI_API_KEY'),
                ]) {
                    sh '''
                        trap 'docker logout "$IMAGE_REGISTRY"' EXIT
                        echo "$IMAGE_PASSWORD" | docker login -u "$IMAGE_USERNAME" --password-stdin "$IMAGE_REGISTRY"
                        cd /app/jenkins/petclinic
                        OPENAI_API_KEY="$OPENAI_API_KEY" docker compose up -d
                    '''
                }
            }
        }
    }
    post {
        always {
            sh 'docker image prune -af'
        }
    }
}