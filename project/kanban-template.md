# GitHub Project Board Configuration

This document outlines the structure for the GitHub Project board for tracking FreeIPA-Hadoop integration implementation.

## Board Columns

### To Do
Tasks that are identified but not yet started. These should be prioritized based on dependencies.

### In Progress
Tasks currently being worked on. Each task should have an assignee and ideally should not stay in this column for more than two weeks.

### Review
Tasks that are completed but require review or testing before being considered done.

### Done
Tasks that are completed, reviewed, and verified.

## Issue Labels

### Priority Labels
- `priority: high` - Critical for project progress
- `priority: medium` - Important but not blocking
- `priority: low` - Nice to have

### Type Labels
- `type: infrastructure` - Related to infrastructure setup
- `type: authentication` - Related to authentication mechanisms
- `type: authorization` - Related to authorization policies
- `type: documentation` - Related to project documentation
- `type: automation` - Related to automation scripts and tools

### Service Labels
- `service: freeipa` - FreeIPA specific tasks
- `service: hdfs` - HDFS integration tasks
- `service: yarn` - YARN integration tasks
- `service: ambari` - Ambari integration tasks
- `service: ranger` - Ranger integration tasks
- `service: hue` - Hue integration tasks
- `service: impala` - Impala integration tasks
- `service: hive` - Hive integration tasks

### Status Labels
- `status: blocked` - Task is blocked by a dependency
- `status: needs-discussion` - Task requires team discussion
- `status: deprecated` - Task is no longer relevant

## Sample Issues

1. **FreeIPA Server Installation**
   - Type: infrastructure
   - Service: freeipa
   - Priority: high
   - Description: Install and configure FreeIPA server with required services (DNS, NTP, LDAP, Kerberos)

2. **HDFS Kerberos Integration**
   - Type: authentication
   - Service: hdfs
   - Priority: high
   - Description: Configure HDFS to use Kerberos authentication with principals from FreeIPA

3. **Apache Ranger Policy Templates**
   - Type: authorization
   - Service: ranger
   - Priority: medium
   - Description: Create policy templates in Ranger for common access patterns

4. **User Provisioning Automation**
   - Type: automation
   - Service: freeipa
   - Priority: medium
   - Description: Develop scripts to automate user provisioning from FreeIPA to Hadoop services

## Automation Options

The following GitHub Actions can be used to automate project management:

```yaml
name: Issue Management

on:
  issues:
    types: [opened, labeled, unlabeled, assigned, unassigned]

jobs:
  manage_project_cards:
    runs-on: ubuntu-latest
    steps:
      - name: Add to project board
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            // Add issue to project board
            // Move cards based on labels
```

## Milestones

Milestones will be used to track progress through the implementation phases:

1. Infrastructure Setup
2. Core Authentication
3. Service Integrations
4. Authorization Implementation
5. User Management Automation
6. Testing and Documentation 