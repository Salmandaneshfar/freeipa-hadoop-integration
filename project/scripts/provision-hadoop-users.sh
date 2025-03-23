#!/bin/bash
# FreeIPA to Hadoop User Provisioning Script
# This script syncs FreeIPA users to Hadoop services and configures appropriate permissions

# Configuration variables
FREEIPA_SERVER="ipaserver.example.com"
HADOOP_NAMENODE="namenode.example.com"
RANGER_SERVER="ranger.example.com"
HUE_SERVER="hue.example.com"
KEYTAB_DIR="/etc/security/keytabs"
LOG_FILE="/var/log/hadoop-user-provisioning.log"

# Required tools check
tools=("kinit" "ipa" "ldapsearch" "curl" "hdfs" "jq")
for tool in "${tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "ERROR: $tool is required but not installed." | tee -a $LOG_FILE
        exit 1
    fi
done

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Authentication
authenticate() {
    log "Authenticating to FreeIPA"
    
    if [ -f "$KEYTAB_DIR/admin.keytab" ]; then
        kinit -kt $KEYTAB_DIR/admin.keytab admin@EXAMPLE.COM
        if [ $? -ne 0 ]; then
            log "ERROR: Authentication failed using keytab"
            exit 1
        fi
    else
        log "ERROR: Admin keytab not found"
        exit 1
    fi
    
    log "Successfully authenticated to FreeIPA"
}

# Sync users from FreeIPA
sync_users() {
    log "Syncing users from FreeIPA"
    
    # Get all users from FreeIPA
    ipa user-find --all > /tmp/freeipa_users.txt
    
    # Extract relevant user information
    cat /tmp/freeipa_users.txt | grep "User login:" | awk '{print $3}' > /tmp/freeipa_usernames.txt
    
    # Get all groups from FreeIPA
    ipa group-find --all > /tmp/freeipa_groups.txt
    
    log "Retrieved $(wc -l < /tmp/freeipa_usernames.txt) users from FreeIPA"
}

# Create HDFS home directories
create_hdfs_homes() {
    log "Creating HDFS home directories"
    
    kinit -kt $KEYTAB_DIR/hdfs.keytab hdfs/namenode.example.com@EXAMPLE.COM
    
    while read username; do
        # Skip system users
        if [[ $username == *\$ ]] || [[ $username == "admin" ]] || [[ $username == "guest" ]]; then
            continue
        fi
        
        # Create user home directory
        hdfs dfs -mkdir -p /user/$username
        hdfs dfs -chown $username:$username /user/$username
        hdfs dfs -chmod 750 /user/$username
        
        log "Created HDFS home for $username"
    done < /tmp/freeipa_usernames.txt
}

# Configure Ranger policies
configure_ranger_policies() {
    log "Configuring Ranger policies"
    
    # Authenticate to Ranger API
    auth_response=$(curl -s -u admin:rangerpassword -X GET http://$RANGER_SERVER:6080/service/public/v2/api/token)
    token=$(echo $auth_response | jq -r '.token')
    
    # Check if token was obtained
    if [ -z "$token" ] || [ "$token" == "null" ]; then
        log "ERROR: Failed to authenticate to Ranger API"
        return 1
    fi
    
    # Get groups
    while read group; do
        # Skip system groups
        if [[ $group == "admins" ]] || [[ $group == "ipausers" ]]; then
            continue
        fi
        
        # Create policy JSON based on group
        cat > /tmp/ranger_policy.json <<EOF
{
  "service": "hdfs-cluster1",
  "name": "${group}_home_dir_access",
  "description": "Access policy for $group users",
  "isEnabled": true,
  "isAuditEnabled": true,
  "resources": {
    "path": {
      "values": ["/user/{USER}"],
      "isRecursive": true
    }
  },
  "policyItems": [
    {
      "groups": ["$group"],
      "accesses": [
        {"type": "read", "isAllowed": true},
        {"type": "write", "isAllowed": true},
        {"type": "execute", "isAllowed": true}
      ]
    }
  ]
}
EOF
        
        # Submit policy to Ranger
        curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" \
             -d @/tmp/ranger_policy.json http://$RANGER_SERVER:6080/service/public/v2/api/policy
        
        log "Created Ranger policy for group $group"
    done < <(grep "Group name:" /tmp/freeipa_groups.txt | awk '{print $3}')
}

# Configure Hue groups
configure_hue_groups() {
    log "Configuring Hue groups"
    
    # This would typically involve API calls to Hue
    # For this script, we'll just demonstrate the concept
    
    log "Hue integration would happen here"
}

# Main execution
main() {
    log "Starting user provisioning process"
    
    authenticate
    sync_users
    create_hdfs_homes
    configure_ranger_policies
    configure_hue_groups
    
    log "User provisioning completed successfully"
}

# Execute main function
main 