// CYROID Red Team Lab - Jenkins Security Configuration
// Sets up weak authentication for training purposes

import jenkins.model.*
import hudson.security.*
import hudson.model.*

def instance = Jenkins.getInstance()

// Create security realm with users
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
hudsonRealm.createAccount("developer", "Dev2024!")
instance.setSecurityRealm(hudsonRealm)

// Set up authorization - admin has full access, developer can build
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, "admin")
strategy.add(Jenkins.READ, "developer")
strategy.add(Item.BUILD, "developer")
strategy.add(Item.READ, "developer")
strategy.add(Item.WORKSPACE, "developer")
// Allow anonymous read (for reconnaissance)
strategy.add(Jenkins.READ, "anonymous")
instance.setAuthorizationStrategy(strategy)

instance.save()

println "Jenkins security configured with weak credentials for training"
