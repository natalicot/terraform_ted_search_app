def comit="\$(./checkcommit.sh)"
def version="\$(./calculate.sh)"
pipeline {

    agent any

    triggers {
        gitlab(
            triggerOnPush: true,
            triggerOnMergeRequest: true,
            branchFilterType: 'All',
            addVoteOnMergeRequest: true)
    }

    tools { 
        terraform 'terraform' 
    }

    stages { 
        stage('build') {
            
            steps{
                dir("./app"){
                    script{
                        sh "mvn verify"
                    }
                }
            }
        }
        
        stage('E2E_test'){  
            steps{
                dir("./app"){
                    script{
                        sh "chmod +x ./target/embedash-1.1-SNAPSHOT.jar"
                       sh "docker run -d --network=ted-search_default -p 9195:9191 --name app spotify/foobar:1.1-SNAPSHOT"
                       sh "chmod 700 ./E2E_test.sh"
                       sh "./E2E_test.sh"
                    }
                }
                
            }
        }
            
        
        stage('deploy'){   
            when {
                expression { BRANCH_NAME =~ /^(master$)/ }
            }
            
            steps{
                script{
                    withCredentials([[$class: 'UsernamePasswordMultiBinding',credentialsId: 'aws',usernameVariable: 'AWS_ACCESS_KEY_ID',passwordVariable: 'AWS_SECRET_ACCESS_KEY']]){
                        sh "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
                        sh "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" 
                        sh "terraform init"
                        sh "terraform apply -auto-approve"
                    }
                }
                
            }
            
            
        }

        // stage('publish') {
        //     when {
        //          expression { BRANCH_NAME =~ /^(master$)|(release\/*)/}
        //      }
        //     steps{
        //         script{
        //         configFilsdsdeProvider([configFile(fileId: 'mvn-setings', variable: 'MAVEN_SETTINGS')]) {
        //             sh 'mvn -s $MAVEN_SETTINGS clean deploy'
        //             }
        //         }
        //     }
        // }
        // stage('deploy'){
        //     when {
        //         expression { BRANCH_NAME =~ /^(release\/*)/}
        //     }
        //     steps{
        //         configFileProvider(
        //         [configFile(fileId: 'mvn-setings', variable: 'MAVEN_SETTINGS')]) {
        //             sh "mvn versions:set -DnewVersion=$version"
        //             sh "mvn -s $MAVEN_SETTINGS deploy -DskipTests"
        //             sh "git tag $version $BRANCH_NAME"
        //             sh "git push --tags"
        //         }

        //     }
        // }
    }
    post { 
        always { 
            sh 'docker rm -f app || true'
        }
        failure {
            updateGitlabCommitStatus state: 'failed'
        }
        success {
            updateGitlabCommitStatus state: 'success'
        }
    }
        
}

//zanalytics branch