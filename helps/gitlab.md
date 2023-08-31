# Helps Gitlab

## Deploy kubernetes operator

<https://docs.gitlab.com/operator/installation.html>

```sh
GL_OPERATOR_VERSION="0.22.1" # https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/releases
PLATFORM=kubernetes # or "openshift"
kubectl create namespace gitlab-system
kubectl apply -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${PLATFORM}-${GL_OPERATOR_VERSION}.yaml
kubectl -n gitlab-system apply -f configs/gitlab/gitlab.yaml
```

## Deploy gitlab with helm

kubectl create namespace gitlab
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --set certmanager.installCRDs=false \
  --namespace gitlab \
  --timeout 600s \
  --set global.hosts.domain=skynet.com.br \
  --set global.edition=ce \
  --set certmanager-issuer.email=marcos.silvestrini@gmail.com \
  --set postgresql.image.tag=13.6.0 \
  --set gitlab.migrations.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ce \
  --set gitlab.sidekiq.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce \
  --set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce \
  --set gitlab.unicorn.workhorse.image=registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce

## Chart

## NOTICE
#
# Due to the scope and complexity of this chart, all possible values are
# not documented in this file. Extensive documentation is available.
#
# Please read the docs: https://docs.gitlab.com/charts/
#
# Because properties are regularly added, updated, or relocated, it is
# _strongly suggest_ to not "copy and paste" this YAML. Please provide
# Helm only those properties you need, and allow the defaults to be
# provided by the version of this chart at the time of deployment.
## Advanced Configuration
## https://docs.gitlab.com/charts/advanced
#
# Documentation for advanced configuration, such as
# - External PostgreSQL
# - External Gitaly
# - External Redis
# - External NGINX
# - External Object Storage providers
# - PersistentVolume configuration
## The global properties are used to configure multiple charts at once.
## https://docs.gitlab.com/charts/charts/globals
global:
  edition: ce
  common:
    labels: {}
  image: {}
    # pullPolicy: IfNotPresent
    # pullSecrets: []
  ## Supplemental Pod labels. Will not be used for selectors.
  pod:
    labels: {}
  ## https://docs.gitlab.com/charts/installation/deployment#deploy-the-community-edition
  ## https://docs.gitlab.com/charts/charts/globals#gitlab-version
  # gitlabVersion:
  ## https://docs.gitlab.com/charts/charts/globals#application-resource
  application:
    create: false
    links: []
    allowClusterRoles: true
  ## https://docs.gitlab.com/charts/charts/globals#configure-host-settings
  hosts:
    domain: gestorp.com.br
    hostSuffix:
    https: true
    externalIP: 2.2.2.0
    ssh: ~
    gitlab:
      https: true
      hostnameOverride: gitlab.gestorp.com.br
    minio:
      https: true
    registry: {}
    tls: {}
    smartcard: {}
    kas: {}
    pages: {}
  ## https://docs.gitlab.com/charts/charts/globals#configure-ingress-settings
  ingress:
    configureCertmanager: false
    class: nginx
    annotations: {}
    enabled: true
    tls: {}
    path: /
    pathType: Prefix
  # Override the API version to use for HorizontalPodAutoscaler
  hpa:
    apiVersion: ""
  # Override the API version to use for PodDisruptionBudget
  pdb:
    apiVersion: ""
  # Override the API version to use for CronJob
  batch:
    cronJob:
      apiVersion: ""
  gitlab:
    ## Enterprise license for this GitLab installation
    ## Secret created according to https://docs.gitlab.com/charts/installation/secrets#initial-enterprise-license
    ## If allowing shared-secrets generation, this is OPTIONAL.
    license: {}
      # secret: RELEASE-gitlab-license
      # key: license
  ## Initial root password for this GitLab installation
  ## Secret created according to https://docs.gitlab.com/charts/installation/secrets#initial-root-password
  ## If allowing shared-secrets generation, this is OPTIONAL.
  initialRootPassword:
    secret: gitlab-initial-root-password
    key: password
  ## https://docs.gitlab.com/charts/charts/globals#configure-postgresql-settings
  psql:
    connectTimeout:
    keepalives:
    keepalivesIdle:
    keepalivesInterval:
    keepalivesCount:
    tcpUserTimeout:
    password: {}
      # useSecret:
      # secret:
      # key:
      # file:
    # host: postgresql.hostedsomewhere.else
    # port: 123
    # username: gitlab
    # database: gitlabhq_production
    # applicationName:
    # preparedStatements: false
    # databaseTasks: true VX9NVPx0J0LKWqxUqtzZ2e4r
  ## https://docs.gitlab.com/charts/charts/globals#configure-redis-settings
  redis:
    password:
      enabled: true
      secret: redis-password
      key: password
    # host: redis.hostedsomewhere.else
    # port: 6379
    # sentinels:
    #   - host:
    #     port:
  ## https://docs.gitlab.com/charts/charts/globals#configure-gitaly-settings
  gitaly:
    persistence:
      size: 1Gi
    enabled: true
    authToken:
      secret: gitaly-secret
      key: token
    # serviceName:
    internal:
      names: [default]
    external: []
    service:
      name: gitaly
      type: ClusterIP
      externalPort: 8075
      internalPort: 8075
      tls:
        externalPort: 8076
        internalPort: 8076
  praefect:
    enabled: false
    replaceInternalGitaly: true
    authToken: {}
    autoMigrate: true
    dbSecret: {}
    virtualStorages:
      - name: default
        gitalyReplicas: 3
        maxUnavailable: 1
    psql:
      sslMode: disable
    # serviceName:
    service:
      name: praefect
      type: ClusterIP
      externalPort: 8075
      internalPort: 8075
      tls:
        externalPort: 8076
        internalPort: 8076
  ## https://docs.gitlab.com/charts/charts/globals#configure-minio-settings
  minio:
    persistence:
      size: 100Gi
    enabled: true
    credentials:
      secret: gitlab-minio-secret
  ## https://docs.gitlab.com/charts/charts/globals#configure-grafana-integration
  grafana:
    enabled: false
  ## https://docs.gitlab.com/charts/charts/globals#configure-appconfig-settings
  ## Rails based portions of this chart share many settings
  appConfig:
    ## https://docs.gitlab.com/charts/charts/globals#general-application-settings
    # cdnHost:
    enableUsagePing: true
    enableSeatLink: true
    enableImpersonation:
    applicationSettingsCacheSeconds: 60
    defaultCanCreateGroup: true
    usernameChangingEnabled: true
    issueClosingPattern:
    defaultTheme:
    defaultProjectsFeatures:
      issues: true
      mergeRequests: true
      wiki: true
      snippets: true
      builds: true
    webhookTimeout:
    maxRequestDurationSeconds:
    ## https://docs.gitlab.com/charts/charts/globals#cron-jobs-related-settings
    cron_jobs:
      stuck_ci_jobs_worker:
        cron: "0 * * * *"
      pipeline_schedule_worker:
        cron: "19 * * * *"
      expire_build_artifacts_worker:
        cron: "*/7 * * * *"
      ## Flag stuck CI builds as failed
      # stuck_ci_jobs_worker:
      #   cron: "0 * * * *"
      ## Schedule pipelines in the near future
      # pipeline_schedule_worker:
      #   cron: "19 * * * *"
      ## Remove expired build artifacts
      # expire_build_artifacts_worker:
      #   cron: "*/7 * * * *"
      ## Periodically run 'git fsck' on all repositories.
      # repository_check_worker:
      #   cron: "20 * * * *"
      ## Send admin emails once a week
      # admin_email_worker:
      #   cron: "0 0 * * 0"
      ## Remove outdated repository archives
      # repository_archive_cache_worker:
      #   cron: "0 * * * *"
      ## Verify custom GitLab Pages domains
      # pages_domain_verification_cron_worker:
      #   cron: "*/15 * * * *"
      # schedule_migrate_external_diffs_worker:
      #   cron: "15 * * * *"
      ## Prune stale group runners on opted-in namespaces
      # ci_runners_stale_group_runners_prune_worker_cron:
      #   cron: "30 * * * *"
      ## Periodically update ci_runner_versions table with up-to-date versions and status
      # ci_runner_versions_reconciliation_worker:
      #   cron: "@daily"
      ### GitLab Geo
      # Geo Primary only!
      # geo_prune_event_log_worker:
      #   cron: "*/5 * * * *"
      ## GitLab Geo repository sync worker
      # geo_repository_sync_worker:
      #   cron: "*/5 * * * *"
      ## GitLab Geo file download dispatch worker
      # geo_file_download_dispatch_worker:
      #  cron: "*/10 * * * *"
      ## GitLab Geo repository verification primary batch worker
      # geo_repository_verification_primary_batch_worker:
      #   cron: "*/5 * * * *"
      ## GitLab Geo repository verification secondary scheduler worker
      # geo_repository_verification_secondary_scheduler_worker:
      #   cron: "*/5 * * * *"
      ## GitLab Geo migrated local files clean up worker
      # geo_migrated_local_files_clean_up_worker:
      #   cron: "15 */6 * * *"
      ### LDAP
      # ldap_sync_worker:
      #   cron: "30 1 * * *"
      # ldap_group_sync_worker:
      #   cron: "0 * * * *"
      ### Snapshot active user statistics
      # historical_data_worker:
      #   cron: "0 12 * * *"
      # loose_foreign_keys_cleanup_worker_cron:
      #   cron: "*/5 * * * *"
    ## https://docs.gitlab.com/charts/charts/globals#content-security-policy
    contentSecurityPolicy:
      enabled: false
      report_only: true
      # directives: {}
    ## https://docs.gitlab.com/charts/charts/globals#gravatarlibravatar-settings
    gravatar:
      plainUrl: "https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon"
      sslUrl: "https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon"
    ## https://docs.gitlab.com/charts/charts/globals#hooking-analytics-services-to-the-gitlab-instance
    extra:
      googleAnalyticsId:
      matomoUrl:
      matomoSiteId:
      matomoDisableCookies:
      oneTrustId:
      googleTagManagerNonceId:
      bizible:
    ## https://docs.gitlab.com/charts/charts/globals#lfs-artifacts-uploads-packages-external-mr-diffs-and-dependency-proxy
    object_store:
      enabled: false
      proxy_download: true
      storage_options: {}
        # server_side_encryption:
        # server_side_encryption_kms_key_id
      connection: {}
        # secret:
        # key:
    lfs:
      enabled: true
      proxy_download: true
      bucket: git-lfs
      connection: {}
        # secret:
        # key:
    artifacts:
      enabled: true
      proxy_download: true
      bucket: gitlab-artifacts
      connection: {}
        # secret:
        # key:
    uploads:
      enabled: true
      proxy_download: true
      bucket: gitlab-uploads
      connection: {}
        # secret:
        # key:
    packages:
      enabled: true
      proxy_download: true
      bucket: gitlab-packages
      connection: {}
    externalDiffs:
      enabled: false
      when:
      proxy_download: true
      bucket: gitlab-mr-diffs
      connection: {}
    terraformState:
      enabled: false
      bucket: gitlab-terraform-state
      connection: {}
    ciSecureFiles:
      enabled: false
      bucket: gitlab-ci-secure-files
      connection: {}
    dependencyProxy:
      enabled: false
      proxy_download: true
      bucket: gitlab-dependency-proxy
      connection: {}
    backups:
      bucket: gitlab-backups
      tmpBucket: tmp
    ## https://docs.gitlab.com/charts/installation/command-line-options.html#incoming-email-configuration
    ## https://docs.gitlab.com/charts/charts/gitlab/mailroom/index.html#incoming-email
    incomingEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret: ""
        key: password
      expungeDeleted: false
      logger:
        logPath: "/dev/stdout"
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}
        # secret:
        # key:
    ## https://docs.gitlab.com/charts/charts/gitlab/mailroom/index.html#service-desk-email
    serviceDeskEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret: ""
        key: password
      expungeDeleted: false
      logger:
        logPath: "/dev/stdout"
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}
        # secret:
        # key:
    ## https://docs.gitlab.com/charts/charts/globals#ldap
    ldap:
      # prevent the use of LDAP for sign-in via web.
      preventSignin: false
      servers: {}
      ## See documentation for complete example of a configured LDAP server
    ## https://docs.gitlab.com/charts/charts/globals#kas-settings
    gitlab_kas: {}
      # secret:
      # key:
      # enabled:
      # externalUrl:
      # internalUrl:
    ## https://docs.gitlab.com/charts/charts/globals#omniauth
    omniauth:
      enabled: false
      autoSignInWithProvider:
      syncProfileFromProvider: []
      syncProfileAttributes: [email]
      allowSingleSignOn: [saml]
      blockAutoCreatedUsers: true
      autoLinkLdapUser: false
      autoLinkSamlUser: false
      autoLinkUser: []
      externalProviders: []
      allowBypassTwoFactor: []
      providers: []
      # - secret: gitlab-google-oauth2
      #   key: provider
    ## https://do...