parameters {
    string(defaultValue: '172.20.19.19:5000/', description: '', name: 'RegistryURL')
	string(defaultValue: 'Test', description: '', name: 'AppName')
	string(defaultValue: '80', description: '', name: 'AppPort')
	string(defaultValue: 'micro-system', description: '', name: 'NameSpace')
	string(defaultValue: 'helm-cred-repo-id', description: '', name: 'HelmCredId')
	string(defaultValue: 'hcl', description: '', name: 'Identifier')
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
		    sh 'sleep 15s'
		}
        def repository
        stage ('Docker') {
            container ('docker') {
			    withDockerRegistry([url: "", credentialsId: "${params.HelmCredId}"]) {
					sh "docker build -t hclcloudworks/cloudworks:${params.AppName}.${env.BUILD_NUMBER} ."
					sh "docker push hclcloudworks/cloudworks:${params.AppName}.${env.BUILD_NUMBER} "
				}
            }
        }
        stage ('Deploy') {
            container ('helm') {
                sh "helm init --client-only --skip-refresh"
                sh "helm upgrade --install --namespace ${params.NameSpace} --wait --set service.identifier=${params.Identifier},service.port=${params.AppPort},service.name=${params.AppName},image.repository=hclcloudworks/cloudworks,image.tag=${params.AppName}.${env.BUILD_NUMBER} ${params.AppName} install/base/install/helm -f Values.yaml"
			}
        }
    }
	
}
