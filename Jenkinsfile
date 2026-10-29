pipeline {
    agent { label 'build-agent' }
    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }
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
                                            string (credentialsId: 'IMAGE_PASSWORD', variable: 'IMAGE_PASSWORD')
                                        ]) {
                                            sh '''
                                                trap 'docker logout "$IMAGE_REGISTRY"' EXIT
                                                echo "$IMAGE_PASSWORD" | docker login -u "$IMAGE_USERNAME" --password-stdin "$IMAGE_REGISTRY"
                                                docker buildx build --build-arg "SERVICE=$SERVICE" -t "$IMAGE_REGISTRY/$IMAGE_PROJECT/$SERVICE:$GIT_COMMIT" --cache-from "type=registry,ref=$IMAGE_REGISTRY/$IMAGE_PROJECT/$SERVICE:buildcache"  --cache-to "type=registry,ref=$IMAGE_REGISTRY/$IMAGE_PROJECT/$SERVICE:buildcache,mode=max" --push . 
                                                yq -i '.services[strenv(SERVICE_SHORT)].image = strenv(IMAGE_REGISTRY)+"/"+strenv(IMAGE_PROJECT)+"/"+strenv(SERVICE)+":"+strenv(GIT_COMMIT)' /app/jenkins/petclinic/charts/petclinic/values.yaml
                                            '''
                                        }
                                    }
                                }
                            //}
                        }
                        //parallel parallelStages
                        withCredentials ([
                            string (credentialsId: 'GITOPS_URL', variable: 'GITOPS_URL')
                        ]) {
                            sh '''
                                cd /app/jenkins/petclinic
                                git add .
                                if git diff --cached --quiet; then
                                    echo "No changes to commit."
                                else
                                    code=$?
                                    if [ "$code" -eq 1 ]; then
                                        git commit -m "ci(agc): update values.yaml - by build: $BUILD_NUMBER"
                                    else
                                        echo "git diff failed with exit code $code" >&2
                                        exit "$code"
                                    fi
                                fi
                                git -c credential.helper= push "$GITOPS_URL" HEAD:main
                            '''
                        }
                    } else {
                        echo 'No services need to be built.'
                    }
                }
            }
        }
    }
}