pipeline {
  agent any
  stages {
    stage('Build Image') {
      steps {
        git(branch: 'main', url: 'https://github.com/CapKenR/blog')
        sh 'kp image build'
      }
    }

    stage('Deploy to Dev') {
      steps {
        sh 'helm upgrade --install '
      }
    }

  }
}