parameters {
    string(defaultValue: '172.20.19.19:5000/', description: '', name: 'RegistryURL')
	string(defaultValue: 'Test', description: '', name: 'AppName')
	string(defaultValue: '80', description: '', name: 'AppPort')
	string(defaultValue: 'micro-system', description: '', name: 'NameSpace')
	string(defaultValue: 'helm-cred-repo-id', description: '', name: 'HelmCredId')
}
podTemplate(
    label: 'mypod', 
    inheritFrom: 'default',
    containers: [
        containerTemplate(
            name: 'docker', 
            image: 'docker:18.02',
            ttyEnabled: true,
            command: 'cat'
        ),
        containerTemplate(
            name: 'helm', 
            image: 'lachlanevenson/k8s-helm:v2.11.0',
            ttyEnabled: true,
            command: 'cat'
        )
    ],
    volumes: [
        hostPathVolume(
            hostPath: '/var/run/docker.sock',
            mountPath: '/var/run/docker.sock'
        )
    ]
) 
{
    node('mypod') {
        def commitId
        stage ('Extract') {
            checkout scm
            commitId = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
			checkout([$class: 'GitSCM', 
				branches: [[name: '*/master']], 
				doGenerateSubmoduleConfigurations: false, 
				extensions: [[$class: 'CleanCheckout'],[$class: 'RelativeTargetDirectory', relativeTargetDir: 'install']], 
				submoduleCfg: [], 
				userRemoteConfigs: [[credentialsId: "${params.HelmCredId}", url: 'https://bitbucket.org/hclswz/devops-mgmt.git']]
			])
			sh 'ls -ltr'
        }
		stage ('UnitTest') {
		    sh 'sleep 1m'
		}
        def repository
        stage ('Docker') {
            container ('docker') {
			    withDockerRegistry([url: "http://${params.RegistryURL}"]) {
					sh "docker build -t ${params.RegistryURL}${params.AppName}:${env.BUILD_NUMBER} ."
					sh "docker push ${params.RegistryURL}${params.AppName}:${env.BUILD_NUMBER} "
				}
            }
        }
        stage ('Deploy') {
            container ('helm') {
                sh "helm init --client-only --skip-refresh"
                sh "helm upgrade --install --namespace ${params.NameSpace} --wait --set service.port=${params.AppPort},service.name=${params.AppName},image.repository=${params.RegistryURL}${params.AppName},image.tag=${env.BUILD_NUMBER} ${params.AppName} install/base/install/helm"
			}
        }
    }
	
}

