pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['DEPLOY', 'ROLLBACK'],
            description: 'Choose the pipeline action'
        )
    }

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
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

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
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

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
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

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
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                sh '''
                    ./mvnw package -DskipTests \
                      -Duser.timezone=Asia/Kolkata
                '''
            }
        }

        stage('Rollback') {
            when {
                expression {
                    params.ACTION == 'ROLLBACK'
                }
            }

            steps {
                echo 'Rollback workflow selected.'
                echo 'Rollback logic will be added next.'
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

// Github webhook trigger test
