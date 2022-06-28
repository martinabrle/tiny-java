param Spring_maabrle_spring_apps_name string = 'maabrle-spring-apps'
param vaults_maabrle_spring_apps_kv_name string = 'maabrle-spring-apps-kv'
param servers_maabrle_todo_pg_name string = 'maabrle-todo-pg'
param components_maabrle_springapps_insights_name string = 'maabrle-springapps-insights'
param smartdetectoralertrules_failure_anomalies_maabrle_springapps_insights_name string = 'failure anomalies - maabrle-springapps-insights'
param actiongroups_application_insights_smart_detection_externalid string = '/subscriptions/66443209-bef6-4fde-a74d-6155cb9f9db5/resourceGroups/maabrle-todo-mi_rg/providers/microsoft.insights/actiongroups/application insights smart detection'

resource Spring_maabrle_spring_apps_name_resource 'Microsoft.AppPlatform/Spring@2022-05-01-preview' = {
  name: Spring_maabrle_spring_apps_name
  location: 'eastus'
  tags: {
    Department: 'RESEARCH'
    CostCenter: 'FIN'
    DeleteNightly: 'true'
    DeleteWeekly: 'true'
  }
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    zoneRedundant: false
    networkProfile: {
    }
  }
}

resource servers_maabrle_todo_pg_name_resource 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: servers_maabrle_todo_pg_name
  location: 'eastus'
  tags: {
    CostCenter: 'FIN'
    Department: 'RESEARCH'
  }
  sku: {
    name: 'B_Gen5_1'
    tier: 'Basic'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    storageProfile: {
      storageMB: 5120
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Disabled'
    }
    version: '11'
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLSEnforcementDisabled'
    infrastructureEncryption: 'Disabled'
    publicNetworkAccess: 'Enabled'
  }
}

resource components_maabrle_springapps_insights_name_resource 'microsoft.insights/components@2020-02-02' = {
  name: components_maabrle_springapps_insights_name
  location: 'eastus'
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: 90
    IngestionMode: 'ApplicationInsights'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource vaults_maabrle_spring_apps_kv_name_resource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: vaults_maabrle_spring_apps_kv_name
  location: 'eastus'
  tags: {
    CostCenter: 'FIN'
    DeleteNightly: 'true'
    DeleteWeekly: 'true'
    Department: 'RESEARCH'
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: '30adb879-45b4-49c3-bf8b-7731fcce5394'
    accessPolicies: [
      {
        tenantId: '30adb879-45b4-49c3-bf8b-7731fcce5394'
        objectId: '1a1f9692-f436-4adc-b646-7703e49759a3'
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'GetRotationPolicy'
            'SetRotationPolicy'
            'Rotate'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    vaultUri: 'https://${vaults_maabrle_spring_apps_kv_name}.vault.azure.net/'
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

resource smartdetectoralertrules_failure_anomalies_maabrle_springapps_insights_name_resource 'microsoft.alertsmanagement/smartdetectoralertrules@2021-04-01' = {
  name: smartdetectoralertrules_failure_anomalies_maabrle_springapps_insights_name
  location: 'global'
  properties: {
    description: 'Failure Anomalies notifies you of an unusual rise in the rate of failed HTTP requests or dependency calls.'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT1M'
    detector: {
      id: 'FailureAnomaliesDetector'
    }
    scope: [
      components_maabrle_springapps_insights_name_resource.id
    ]
    actionGroups: {
      groupIds: [
        actiongroups_application_insights_smart_detection_externalid
      ]
    }
  }
}

resource Spring_maabrle_spring_apps_name_todo_app 'Microsoft.AppPlatform/Spring/apps@2022-05-01-preview' = {
  parent: Spring_maabrle_spring_apps_name_resource
  name: 'todo-app'
  location: 'eastus'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    addonConfigs: {
      applicationConfigurationService: {
      }
      serviceRegistry: {
      }
    }
    public: true
    fqdn: 'maabrle-spring-apps.azuremicroservices.io'
    httpsOnly: false
    temporaryDisk: {
      sizeInGB: 5
      mountPath: '/tmp'
    }
    persistentDisk: {
      sizeInGB: 0
      mountPath: '/persistent'
    }
    enableEndToEndTLS: false
  }
}

resource servers_maabrle_todo_pg_name_ActiveDirectory 'Microsoft.DBforPostgreSQL/servers/administrators@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'martin@maabrle.onmicrosoft.com'
    sid: '1a1f9692-f436-4adc-b646-7703e49759a3'
    tenantId: '30adb879-45b4-49c3-bf8b-7731fcce5394'
  }
}

resource servers_maabrle_todo_pg_name_array_nulls 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'array_nulls'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_analyze_scale_factor 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_analyze_scale_factor'
  properties: {
    value: '0.05'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_analyze_threshold 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_analyze_threshold'
  properties: {
    value: '50'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_freeze_max_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_freeze_max_age'
  properties: {
    value: '200000000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_max_workers 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_max_workers'
  properties: {
    value: '3'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_multixact_freeze_max_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_multixact_freeze_max_age'
  properties: {
    value: '400000000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_naptime 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_naptime'
  properties: {
    value: '15'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_vacuum_cost_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_vacuum_cost_delay'
  properties: {
    value: '20'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_vacuum_cost_limit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_vacuum_cost_limit'
  properties: {
    value: '-1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_vacuum_scale_factor 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_vacuum_scale_factor'
  properties: {
    value: '0.05'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_vacuum_threshold 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_vacuum_threshold'
  properties: {
    value: '50'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_autovacuum_work_mem 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'autovacuum_work_mem'
  properties: {
    value: '-1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_azure_replication_support 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'azure.replication_support'
  properties: {
    value: 'REPLICA'
    source: 'user-override'
  }
}

resource servers_maabrle_todo_pg_name_backend_flush_after 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'backend_flush_after'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_backslash_quote 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'backslash_quote'
  properties: {
    value: 'safe_encoding'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_bgwriter_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'bgwriter_delay'
  properties: {
    value: '20'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_bgwriter_flush_after 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'bgwriter_flush_after'
  properties: {
    value: '64'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_bgwriter_lru_maxpages 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'bgwriter_lru_maxpages'
  properties: {
    value: '100'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_bgwriter_lru_multiplier 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'bgwriter_lru_multiplier'
  properties: {
    value: '2'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_bytea_output 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'bytea_output'
  properties: {
    value: 'hex'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_check_function_bodies 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'check_function_bodies'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_checkpoint_completion_target 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'checkpoint_completion_target'
  properties: {
    value: '0.9'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_checkpoint_warning 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'checkpoint_warning'
  properties: {
    value: '30'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_client_encoding 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'client_encoding'
  properties: {
    value: 'sql_ascii'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_client_min_messages 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'client_min_messages'
  properties: {
    value: 'notice'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_commit_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'commit_delay'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_commit_siblings 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'commit_siblings'
  properties: {
    value: '5'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_connection_throttling 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'connection_throttling'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_constraint_exclusion 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'constraint_exclusion'
  properties: {
    value: 'partition'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_cpu_index_tuple_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'cpu_index_tuple_cost'
  properties: {
    value: '0.005'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_cpu_operator_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'cpu_operator_cost'
  properties: {
    value: '0.0025'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_cpu_tuple_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'cpu_tuple_cost'
  properties: {
    value: '0.01'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_cursor_tuple_fraction 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'cursor_tuple_fraction'
  properties: {
    value: '0.1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_datestyle 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'datestyle'
  properties: {
    value: 'iso, mdy'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_deadlock_timeout 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'deadlock_timeout'
  properties: {
    value: '1000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_debug_print_parse 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'debug_print_parse'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_debug_print_plan 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'debug_print_plan'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_debug_print_rewritten 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'debug_print_rewritten'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_default_statistics_target 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'default_statistics_target'
  properties: {
    value: '100'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_default_text_search_config 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'default_text_search_config'
  properties: {
    value: 'pg_catalog.english'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_default_transaction_deferrable 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'default_transaction_deferrable'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_default_transaction_isolation 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'default_transaction_isolation'
  properties: {
    value: 'read committed'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_default_transaction_read_only 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'default_transaction_read_only'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_default_with_oids 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'default_with_oids'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_effective_cache_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'effective_cache_size'
  properties: {
    value: '196608'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_bitmapscan 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_bitmapscan'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_hashagg 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_hashagg'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_hashjoin 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_hashjoin'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_indexonlyscan 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_indexonlyscan'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_indexscan 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_indexscan'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_material 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_material'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_mergejoin 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_mergejoin'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_nestloop 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_nestloop'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_partitionwise_aggregate 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_partitionwise_aggregate'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_partitionwise_join 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_partitionwise_join'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_seqscan 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_seqscan'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_sort 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_sort'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_enable_tidscan 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'enable_tidscan'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_escape_string_warning 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'escape_string_warning'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_exit_on_error 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'exit_on_error'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_extra_float_digits 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'extra_float_digits'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_force_parallel_mode 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'force_parallel_mode'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_from_collapse_limit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'from_collapse_limit'
  properties: {
    value: '8'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo_effort 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo_effort'
  properties: {
    value: '5'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo_generations 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo_generations'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo_pool_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo_pool_size'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo_seed 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo_seed'
  properties: {
    value: '0.0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo_selection_bias 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo_selection_bias'
  properties: {
    value: '2.0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_geqo_threshold 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'geqo_threshold'
  properties: {
    value: '12'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_gin_fuzzy_search_limit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'gin_fuzzy_search_limit'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_gin_pending_list_limit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'gin_pending_list_limit'
  properties: {
    value: '4096'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_hot_standby_feedback 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'hot_standby_feedback'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_idle_in_transaction_session_timeout 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'idle_in_transaction_session_timeout'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_intervalstyle 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'intervalstyle'
  properties: {
    value: 'postgres'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_join_collapse_limit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'join_collapse_limit'
  properties: {
    value: '8'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_lc_monetary 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'lc_monetary'
  properties: {
    value: 'English_United States.1252'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_lc_numeric 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'lc_numeric'
  properties: {
    value: 'English_United States.1252'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_lo_compat_privileges 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'lo_compat_privileges'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_lock_timeout 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'lock_timeout'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_autovacuum_min_duration 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_autovacuum_min_duration'
  properties: {
    value: '-1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_checkpoints 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_checkpoints'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_connections 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_connections'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_disconnections 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_disconnections'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_duration 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_duration'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_error_verbosity 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_error_verbosity'
  properties: {
    value: 'default'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_line_prefix 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_line_prefix'
  properties: {
    value: '%t-%c-'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_lock_waits 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_lock_waits'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_min_duration_statement 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_min_duration_statement'
  properties: {
    value: '-1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_min_error_statement 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_min_error_statement'
  properties: {
    value: 'error'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_min_messages 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_min_messages'
  properties: {
    value: 'warning'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_replication_commands 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_replication_commands'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_retention_days 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_retention_days'
  properties: {
    value: '3'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_statement 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_statement'
  properties: {
    value: 'none'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_statement_stats 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_statement_stats'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_log_temp_files 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'log_temp_files'
  properties: {
    value: '-1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_logging_collector 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'logging_collector'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_maintenance_work_mem 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'maintenance_work_mem'
  properties: {
    value: '131072'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_locks_per_transaction 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_locks_per_transaction'
  properties: {
    value: '64'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_parallel_workers 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_parallel_workers'
  properties: {
    value: '8'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_parallel_workers_per_gather 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_parallel_workers_per_gather'
  properties: {
    value: '2'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_prepared_transactions 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_prepared_transactions'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_replication_slots 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_replication_slots'
  properties: {
    value: '10'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_standby_archive_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_standby_archive_delay'
  properties: {
    value: '30000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_standby_streaming_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_standby_streaming_delay'
  properties: {
    value: '30000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_wal_senders 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_wal_senders'
  properties: {
    value: '10'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_max_wal_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'max_wal_size'
  properties: {
    value: '1024'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_min_parallel_index_scan_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'min_parallel_index_scan_size'
  properties: {
    value: '64'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_min_parallel_table_scan_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'min_parallel_table_scan_size'
  properties: {
    value: '1024'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_min_wal_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'min_wal_size'
  properties: {
    value: '256'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_old_snapshot_threshold 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'old_snapshot_threshold'
  properties: {
    value: '-1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_operator_precedence_warning 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'operator_precedence_warning'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_parallel_leader_participation 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'parallel_leader_participation'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_parallel_setup_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'parallel_setup_cost'
  properties: {
    value: '1000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_parallel_tuple_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'parallel_tuple_cost'
  properties: {
    value: '0.1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_qs_interval_length_minutes 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_qs.interval_length_minutes'
  properties: {
    value: '15'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_qs_max_query_text_length 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_qs.max_query_text_length'
  properties: {
    value: '6000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_qs_query_capture_mode 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_qs.query_capture_mode'
  properties: {
    value: 'none'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_qs_replace_parameter_placeholders 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_qs.replace_parameter_placeholders'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_qs_retention_period_in_days 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_qs.retention_period_in_days'
  properties: {
    value: '7'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_qs_track_utility 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_qs.track_utility'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_stat_statements_max 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_stat_statements.max'
  properties: {
    value: '5000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_stat_statements_save 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_stat_statements.save'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_stat_statements_track 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_stat_statements.track'
  properties: {
    value: 'none'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pg_stat_statements_track_utility 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pg_stat_statements.track_utility'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pgms_wait_sampling_history_period 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pgms_wait_sampling.history_period'
  properties: {
    value: '100'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_pgms_wait_sampling_query_capture_mode 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'pgms_wait_sampling.query_capture_mode'
  properties: {
    value: 'none'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_postgis_gdal_enabled_drivers 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'postgis.gdal_enabled_drivers'
  properties: {
    value: 'DISABLE_ALL'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_quote_all_identifiers 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'quote_all_identifiers'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_random_page_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'random_page_cost'
  properties: {
    value: '4.0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_row_security 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'row_security'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_search_path 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'search_path'
  properties: {
    value: '"$user", public'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_seq_page_cost 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'seq_page_cost'
  properties: {
    value: '1.0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_session_replication_role 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'session_replication_role'
  properties: {
    value: 'origin'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_shared_preload_libraries 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'shared_preload_libraries'
  properties: {
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_statement_timeout 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'statement_timeout'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_synchronize_seqscans 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'synchronize_seqscans'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_synchronous_commit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'synchronous_commit'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_tcp_keepalives_count 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'tcp_keepalives_count'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_tcp_keepalives_idle 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'tcp_keepalives_idle'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_tcp_keepalives_interval 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'tcp_keepalives_interval'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_temp_buffers 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'temp_buffers'
  properties: {
    value: '1024'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_timezone 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'timezone'
  properties: {
    value: 'UTC'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_track_activities 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'track_activities'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_track_activity_query_size 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'track_activity_query_size'
  properties: {
    value: '1024'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_track_commit_timestamp 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'track_commit_timestamp'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_track_counts 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'track_counts'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_track_functions 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'track_functions'
  properties: {
    value: 'none'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_track_io_timing 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'track_io_timing'
  properties: {
    value: 'on'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_transform_null_equals 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'transform_null_equals'
  properties: {
    value: 'off'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_cost_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_cost_delay'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_cost_limit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_cost_limit'
  properties: {
    value: '200'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_cost_page_dirty 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_cost_page_dirty'
  properties: {
    value: '20'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_cost_page_hit 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_cost_page_hit'
  properties: {
    value: '1'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_cost_page_miss 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_cost_page_miss'
  properties: {
    value: '10'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_defer_cleanup_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_defer_cleanup_age'
  properties: {
    value: '0'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_freeze_min_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_freeze_min_age'
  properties: {
    value: '50000000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_freeze_table_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_freeze_table_age'
  properties: {
    value: '150000000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_multixact_freeze_min_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_multixact_freeze_min_age'
  properties: {
    value: '5000000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_vacuum_multixact_freeze_table_age 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'vacuum_multixact_freeze_table_age'
  properties: {
    value: '150000000'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_wal_buffers 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'wal_buffers'
  properties: {
    value: '8192'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_wal_receiver_status_interval 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'wal_receiver_status_interval'
  properties: {
    value: '10'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_wal_writer_delay 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'wal_writer_delay'
  properties: {
    value: '200'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_wal_writer_flush_after 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'wal_writer_flush_after'
  properties: {
    value: '128'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_work_mem 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'work_mem'
  properties: {
    value: '4096'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_xmlbinary 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'xmlbinary'
  properties: {
    value: 'base64'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_xmloption 'Microsoft.DBforPostgreSQL/servers/configurations@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'xmloption'
  properties: {
    value: 'content'
    source: 'system-default'
  }
}

resource servers_maabrle_todo_pg_name_azure_maintenance 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'azure_maintenance'
  properties: {
    charset: 'UTF8'
    collation: 'English_United States.1252'
  }
}

resource servers_maabrle_todo_pg_name_azure_sys 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'azure_sys'
  properties: {
    charset: 'UTF8'
    collation: 'English_United States.1252'
  }
}

resource servers_maabrle_todo_pg_name_postgres 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'postgres'
  properties: {
    charset: 'UTF8'
    collation: 'English_United States.1252'
  }
}

resource servers_maabrle_todo_pg_name_tododb 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'tododb'
  properties: {
    charset: 'UTF8'
    collation: 'English_United States.1252'
  }
}

resource servers_maabrle_todo_pg_name_AllowAll_2022_6_28_23_9_38 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'AllowAll_2022-6-28_23-9-38'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource servers_maabrle_todo_pg_name_AllowAllWindowsAzureIps 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource servers_maabrle_todo_pg_name_ClientIPAddress_2022_6_28_22_45_53 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  parent: servers_maabrle_todo_pg_name_resource
  name: 'ClientIPAddress_2022-6-28_22-45-53'
  properties: {
    startIpAddress: '158.181.126.79'
    endIpAddress: '158.181.126.79'
  }
}

resource components_maabrle_springapps_insights_name_degradationindependencyduration 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'degradationindependencyduration'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'degradationindependencyduration'
      DisplayName: 'Degradation in dependency duration'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_degradationinserverresponsetime 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'degradationinserverresponsetime'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'degradationinserverresponsetime'
      DisplayName: 'Degradation in server response time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_digestMailConfiguration 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'digestMailConfiguration'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'digestMailConfiguration'
      DisplayName: 'Digest Mail Configuration'
      Description: 'This rule describes the digest mail preferences'
      HelpUrl: 'www.homail.com'
      IsHidden: true
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_extension_billingdatavolumedailyspikeextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'extension_billingdatavolumedailyspikeextension'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'extension_billingdatavolumedailyspikeextension'
      DisplayName: 'Abnormal rise in daily data volume (preview)'
      Description: 'This detection rule automatically analyzes the billing data generated by your application, and can warn you about an unusual increase in your application\'s billing costs'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/tree/master/SmartDetection/billing-data-volume-daily-spike.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_extension_canaryextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'extension_canaryextension'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'extension_canaryextension'
      DisplayName: 'Canary extension'
      Description: 'Canary extension'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/'
      IsHidden: true
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_extension_exceptionchangeextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'extension_exceptionchangeextension'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'extension_exceptionchangeextension'
      DisplayName: 'Abnormal rise in exception volume (preview)'
      Description: 'This detection rule automatically analyzes the exceptions thrown in your application, and can warn you about unusual patterns in your exception telemetry.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/abnormal-rise-in-exception-volume.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_extension_memoryleakextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'extension_memoryleakextension'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'extension_memoryleakextension'
      DisplayName: 'Potential memory leak detected (preview)'
      Description: 'This detection rule automatically analyzes the memory consumption of each process in your application, and can warn you about potential memory leaks or increased memory consumption.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/tree/master/SmartDetection/memory-leak.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_extension_securityextensionspackage 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'extension_securityextensionspackage'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'extension_securityextensionspackage'
      DisplayName: 'Potential security issue detected (preview)'
      Description: 'This detection rule automatically analyzes the telemetry generated by your application and detects potential security issues.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/application-security-detection-pack.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_extension_traceseveritydetector 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'extension_traceseveritydetector'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'extension_traceseveritydetector'
      DisplayName: 'Degradation in trace severity ratio (preview)'
      Description: 'This detection rule automatically analyzes the trace logs emitted from your application, and can warn you about unusual patterns in the severity of your trace telemetry.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/degradation-in-trace-severity-ratio.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_longdependencyduration 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'longdependencyduration'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'longdependencyduration'
      DisplayName: 'Long dependency duration'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_migrationToAlertRulesCompleted 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'migrationToAlertRulesCompleted'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'migrationToAlertRulesCompleted'
      DisplayName: 'Migration To Alert Rules Completed'
      Description: 'A configuration that controls the migration state of Smart Detection to Smart Alerts'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: true
      IsEnabledByDefault: false
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    Enabled: false
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_slowpageloadtime 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'slowpageloadtime'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'slowpageloadtime'
      DisplayName: 'Slow page load time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource components_maabrle_springapps_insights_name_slowserverresponsetime 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_maabrle_springapps_insights_name_resource
  name: 'slowserverresponsetime'
  location: 'eastus'
  properties: {
    RuleDefinitions: {
      Name: 'slowserverresponsetime'
      DisplayName: 'Slow server response time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

resource Spring_maabrle_spring_apps_name_todo_app_default 'Microsoft.AppPlatform/Spring/apps/deployments@2022-05-01-preview' = {
  parent: Spring_maabrle_spring_apps_name_todo_app
  name: 'default'
  sku: {
    name: 'S0'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    deploymentSettings: {
      resourceRequests: {
        cpu: '1'
        memory: '1Gi'
      }
      environmentVariables: {
        SPRING_DATASOURCE_USERNAME: '*******@PG_SERVER'
        SPRING_DATASOURCE_PASSWORD: '**********'
        SPRING_DATASOURCE_URL: 'jdbc:postgresql://PG_SERVER.postgres.database.azure.com:5432/tododb'
        SPRING_DATASOURCE_SHOW_SQL: 'true'
      }
      terminationGracePeriodSeconds: 90
      livenessProbe: {
        disableProbe: false
        failureThreshold: 24
        initialDelaySeconds: 60
        periodSeconds: 10
        successThreshold: 1
        timeoutSeconds: 1
        probeAction: {
          type: 'TCPSocketAction'
        }
      }
      readinessProbe: {
        disableProbe: false
        failureThreshold: 3
        initialDelaySeconds: 0
        periodSeconds: 10
        successThreshold: 1
        timeoutSeconds: 1
        probeAction: {
          type: 'TCPSocketAction'
        }
      }
    }
    active: true
    source: {
      version: 'Java_11'
    }
  }
  dependsOn: [

    Spring_maabrle_spring_apps_name_resource
  ]
}