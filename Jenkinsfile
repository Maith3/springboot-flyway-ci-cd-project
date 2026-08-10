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
                withCredentials([
                    usernamePassword(
                        credentialsId: 'flyway-db-credentials',
                        usernameVariable: 'DB_USERNAME',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "========================================="
                        echo "        AUTOMATED FLYWAY ROLLBACK"
                        echo "========================================="

                        chmod +x mvnw

                        ROLLBACK_DIR="src/main/resources/db/rollback"

                        echo "Checking Flyway migration history..."

                        // Get the latest successful migration.
                        MIGRATION_INFO=$(PGPASSWORD="${DB_PASSWORD}" psql \
                            -h "${DB_HOST}" \
                            -p "${DB_PORT}" \
                            -U "${DB_USERNAME}" \
                            -d "${DB_NAME}" \
                            -t -A \
                            -F '|' \
                            -c "
                                SELECT installed_rank, version
                                FROM flyway_schema_history
                                WHERE success = true
                                ORDER BY installed_rank DESC
                                LIMIT 1;
                            "
                        )

                        if [ -z "${MIGRATION_INFO}" ]; then
                            echo "ERROR: No successful Flyway migration found."
                            exit 1
                        fi

                        INSTALLED_RANK=$(echo "${MIGRATION_INFO}" | cut -d'|' -f1)
                        VERSION=$(echo "${MIGRATION_INFO}" | cut -d'|' -f2)

                        echo "Latest successful migration:"
                        echo "  installed_rank = ${INSTALLED_RANK}"
                        echo "  version        = ${VERSION}"

                        // Find the rollback script corresponding to the version.
                        ROLLBACK_FILES=$(find "${ROLLBACK_DIR}" -maxdepth 1 -type f \
                            -name "U${VERSION}__*.sql" -print)

                        ROLLBACK_COUNT=$(printf '%s\\n' "${ROLLBACK_FILES}" | \
                            sed '/^$/d' | wc -l)

                        if [ "${ROLLBACK_COUNT}" -eq 0 ]; then
                            echo "ERROR: No rollback script found for version ${VERSION}."
                            echo "Expected: ${ROLLBACK_DIR}/U${VERSION}__*.sql"
                            exit 1
                        fi

                        if [ "${ROLLBACK_COUNT}" -gt 1 ]; then
                            echo "ERROR: Multiple rollback scripts found for version ${VERSION}:"
                            echo "${ROLLBACK_FILES}"
                            exit 1
                        fi

                        ROLLBACK_FILE="${ROLLBACK_FILES}"

                        echo "Rollback script found:"
                        echo "  ${ROLLBACK_FILE}"

                        echo "Starting atomic rollback transaction..."

                        export ROLLBACK_FILE
                        export INSTALLED_RANK

                        PGPASSWORD="${DB_PASSWORD}" psql \
                            -h "${DB_HOST}" \
                            -p "${DB_PORT}" \
                            -U "${DB_USERNAME}" \
                            -d "${DB_NAME}" \
                            -v ON_ERROR_STOP=1 \
                            -v rollback_file="${ROLLBACK_FILE}" \
                            -v installed_rank="${INSTALLED_RANK}" <<'SQL'

        BEGIN;

        // Execute the dynamically selected rollback script.
        \\i :rollback_file

        // Remove exactly the migration that was rolled back.
        DELETE FROM flyway_schema_history
        WHERE installed_rank = :installed_rank
          AND success = true;

        // Make sure exactly one history row was removed.
        DO $$
        BEGIN
            GET DIAGNOSTICS deleted_rows = ROW_COUNT;
            IF deleted_rows <> 1 THEN
                RAISE EXCEPTION 'Expected to delete exactly one history row, but deleted %.', deleted_rows;
            END IF;
        END
        $$;

        COMMIT;

        SQL

                        echo "========================================="
                        echo "Rollback transaction committed successfully."
                        echo "Rolled back migration version: ${VERSION}"
                        echo "========================================="

                        echo "Verifying rollback..."

                        REMAINING=$(PGPASSWORD="${DB_PASSWORD}" psql \
                            -h "${DB_HOST}" \
                            -p "${DB_PORT}" \
                            -U "${DB_USERNAME}" \
                            -d "${DB_NAME}" \
                            -t -A \
                            -c "
                                SELECT COUNT(*)
                                FROM flyway_schema_history
                                WHERE installed_rank = ${INSTALLED_RANK}
                                  AND success = true;
                            "
                        )

                        if [ "${REMAINING}" -ne 0 ]; then
                            echo "ERROR: Migration history entry still exists."
                            exit 1
                        fi

                        echo "Verification successful."
                        echo "Migration ${VERSION} has been rolled back."
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