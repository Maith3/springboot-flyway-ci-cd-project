pipeline {
    agent any

    environment {
        DB_HOST = 'host.docker.internal'
        DB_PORT = '5432'
        DB_NAME = 'flyway_dev'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'flyway-db-credentials',
                        usernameVariable: 'DB_USERNAME',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        chmod +x mvnw

                        ./mvnw clean test \
                          -Duser.timezone=Asia/Kolkata \
                          -Dspring.datasource.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME} \
                          -Dspring.datasource.username=${DB_USERNAME} \
                          -Dspring.datasource.password=${DB_PASSWORD}
                    '''
                }
            }
        }

        stage('Flyway Validate') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'flyway-db-credentials',
                        usernameVariable: 'DB_USERNAME',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        ./mvnw flyway:validate \
                          -Duser.timezone=Asia/Kolkata \
                          -Dflyway.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME} \
                          -Dflyway.user=${DB_USERNAME} \
                          -Dflyway.password=${DB_PASSWORD}
                    '''
                }
            }
        }

        stage('Flyway Migrate') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'flyway-db-credentials',
                        usernameVariable: 'DB_USERNAME',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        ./mvnw flyway:migrate \
                          -Duser.timezone=Asia/Kolkata \
                          -Dflyway.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME} \
                          -Dflyway.user=${DB_USERNAME} \
                          -Dflyway.password=${DB_PASSWORD}
                    '''
                }
            }
        }

        stage('Package') {
            steps {
                sh '''
                    ./mvnw package -DskipTests \
                      -Duser.timezone=Asia/Kolkata
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'CI/CD pipeline failed.'
        }
    }
}

//Github webhook trigger test