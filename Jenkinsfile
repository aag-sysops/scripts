node {
    // mark the code checkout 'stage'...
    stage 'Checkout'

    //c heckout code from repo
    checkout scm

    // get maven tool
    // ** Note: This 'M3' maven tool must be configured in global config.
    def MvnHome = tool 'M3'

    // mark the code build 'stage'...
    stage 'Build'
    // run the maven build
    sh "${mvnHome}/bin/mvn clean install"
}