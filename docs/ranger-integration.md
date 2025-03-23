# FreeIPA Integration with Apache Ranger

This document details how to integrate FreeIPA with Apache Ranger for centralized authentication and authorization management for Hadoop services.

## Overview

Apache Ranger provides comprehensive security administration and access control for Hadoop ecosystem. By integrating with FreeIPA, you can:

- Centralize user and group management in FreeIPA
- Use Kerberos for authentication
- Leverage LDAP for user/group information
- Implement fine-grained access control policies in Ranger

## Prerequisites

- FreeIPA server installed and configured
- Hadoop cluster with Apache Ranger
- HDFS configured with Kerberos authentication
- Administrative access to both systems

## Integration Steps

### 1. Configure Ranger Admin Server for FreeIPA Authentication

#### 1.1 Create Service Principals in FreeIPA

```bash
# Add Ranger service principal
ipa service-add ranger/rangerserver.example.com@EXAMPLE.COM

# Add HTTP principal for web UI
ipa service-add HTTP/rangerserver.example.com@EXAMPLE.COM
```

#### 1.2 Generate Keytabs

```bash
# Generate keytab for Ranger Admin
ipa-getkeytab -s ipaserver.example.com -p ranger/rangerserver.example.com@EXAMPLE.COM -k /etc/security/keytabs/ranger.keytab

# Set appropriate permissions
chmod 400 /etc/security/keytabs/ranger.keytab
chown ranger:hadoop /etc/security/keytabs/ranger.keytab
```

### 2. Configure Ranger to Use FreeIPA's LDAP

Edit the `install.properties` file for Ranger Admin:

```properties
# Enable LDAP Authentication
AUTHENTICATION_METHOD=LDAP

# FreeIPA LDAP Configuration
AUDIT_LDAP_URL=ldaps://ipaserver.example.com:636
AUDIT_LDAP_BIND_DN=uid=ranger-user,cn=users,cn=accounts,dc=example,dc=com
AUDIT_LDAP_BIND_PASSWORD=password

AUDIT_LDAP_USER_SEARCHBASE=cn=users,cn=accounts,dc=example,dc=com
AUDIT_LDAP_USER_SEARCHFILTER=(&(objectclass=posixAccount)(uid={0}))

AUDIT_LDAP_GROUP_SEARCHBASE=cn=groups,cn=accounts,dc=example,dc=com
AUDIT_LDAP_GROUP_SEARCHFILTER=(objectclass=posixGroup)
AUDIT_LDAP_GROUP_ROLE_ATTRIBUTE=cn
```

### 3. Configure Ranger User Synchronization

Edit `ranger-ugsync-site.xml` to synchronize users and groups from FreeIPA:

```xml
<property>
  <name>ranger.usersync.source.impl.class</name>
  <value>org.apache.ranger.ldapusersync.process.LdapUserGroupBuilder</value>
</property>

<property>
  <name>ranger.usersync.ldap.url</name>
  <value>ldaps://ipaserver.example.com:636</value>
</property>

<property>
  <name>ranger.usersync.ldap.binddn</name>
  <value>uid=ranger-sync,cn=users,cn=accounts,dc=example,dc=com</value>
</property>

<property>
  <name>ranger.usersync.ldap.ldapbindpassword</name>
  <value>password</value>
</property>

<property>
  <name>ranger.usersync.ldap.searchBase</name>
  <value>cn=users,cn=accounts,dc=example,dc=com</value>
</property>

<property>
  <name>ranger.usersync.ldap.user.searchbase</name>
  <value>cn=users,cn=accounts,dc=example,dc=com</value>
</property>

<property>
  <name>ranger.usersync.ldap.user.searchfilter</name>
  <value>(&amp;(objectclass=posixAccount)(uid=*))</value>
</property>

<property>
  <name>ranger.usersync.ldap.user.nameattribute</name>
  <value>uid</value>
</property>

<property>
  <name>ranger.usersync.ldap.group.searchbase</name>
  <value>cn=groups,cn=accounts,dc=example,dc=com</value>
</property>

<property>
  <name>ranger.usersync.ldap.group.searchfilter</name>
  <value>(objectclass=posixGroup)</value>
</property>

<property>
  <name>ranger.usersync.ldap.group.nameattribute</name>
  <value>cn</value>
</property>

<property>
  <name>ranger.usersync.ldap.group.memberattributename</name>
  <value>memberUid</value>
</property>
```

### 4. Configure Ranger Service Plugins

#### 4.1 HDFS Plugin Configuration

Edit `ranger-hdfs-security.xml` on NameNode:

```xml
<property>
  <name>ranger.plugin.hdfs.service.name</name>
  <value>hdfs-cluster1</value>
</property>

<property>
  <name>ranger.plugin.hdfs.policy.source.impl</name>
  <value>org.apache.ranger.admin.client.RangerAdminRESTClient</value>
</property>

<property>
  <name>ranger.plugin.hdfs.policy.rest.url</name>
  <value>https://rangerserver.example.com:6182</value>
</property>

<property>
  <name>ranger.plugin.hdfs.policy.rest.ssl.config.file</name>
  <value>/etc/hadoop/conf/ranger-policymgr-ssl.xml</value>
</property>

<property>
  <name>ranger.plugin.hdfs.policy.pollIntervalMs</name>
  <value>30000</value>
</property>
```

### 5. Create Service Definitions in Ranger

1. Log in to Ranger Admin UI
2. Create a service for HDFS:
   - Service Name: `hdfs-cluster1`
   - Display Name: `HDFS Cluster 1`
   - Active Status: `Enabled`

3. Add repository details:
   - Username: `ranger_hdfs` (service account)
   - Password: `****`
   - NameNode URL: `hdfs://namenode.example.com:8020`
   - Authorization Enabled: `True`
   - Authentication Type: `Kerberos`

### 6. Define Access Policies

Create access policies for different user groups:

1. Create a policy for Data Scientists:
   - Policy Name: `data-science-projects`
   - Resource Path: `/projects/data-science`
   - Group: `data-scientists` (from FreeIPA)
   - Permissions: `Read`, `Write`, `Execute`

2. Create a policy for Data Analysts:
   - Policy Name: `data-analytics-reports`
   - Resource Path: `/data/reports`
   - Group: `data-analysts` (from FreeIPA)
   - Permissions: `Read`, `Execute`

### 7. Testing the Integration

```bash
# Authenticate as a user in the data-scientists group
kinit scientist1@EXAMPLE.COM

# Should succeed
hdfs dfs -ls /projects/data-science
hdfs dfs -put data.csv /projects/data-science/

# Should fail due to policy restrictions
hdfs dfs -ls /data/reports/finance

# Switch to data-analyst user
kdestroy
kinit analyst1@EXAMPLE.COM

# Should succeed
hdfs dfs -ls /data/reports
hdfs dfs -get /data/reports/public/report.csv ./

# Should fail due to policy restrictions
hdfs dfs -put new_data.csv /projects/data-science/
```

## Troubleshooting

### Common Issues

- **User Synchronization Issues**: Check LDAP configuration and synchronization logs
- **Policy Not Applying**: Verify service definition and plugin configuration
- **Authentication Failures**: Check Kerberos principals and keytabs

### Debug Commands

```bash
# Check Ranger Admin logs
tail -f /var/log/ranger/admin/ranger-admin.log

# Check User Sync logs
tail -f /var/log/ranger/usersync/usersync.log

# Check HDFS Audit logs
tail -f /var/log/ranger/hdfs/audit/hdfs-audit.log

# Test LDAP connectivity
ldapsearch -H ldaps://ipaserver.example.com -D "uid=ranger-user,cn=users,cn=accounts,dc=example,dc=com" -w password -b "cn=users,cn=accounts,dc=example,dc=com" "(uid=*)"
```

## References

- [Apache Ranger Documentation](https://ranger.apache.org/docs.html)
- [FreeIPA Documentation](https://www.freeipa.org/page/Documentation)
- [Hadoop Security Guide](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SecureMode.html) 