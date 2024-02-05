// main template for renovate-runner
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.renovate_runner;


// Namespace

local namespace = kube.Namespace(params.namespace.name) {
  metadata+: {
    annotations+: params.namespace.annotations,
    labels+: params.namespace.labels,
  },
};


// Renovate Runners

local config(name) = kube.ConfigMap(name) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/instance': 'renovate-runner',
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
    namespace: params.namespace.name,
  },
  data: {
    'config.json': params.renovate[name].config,
  },
};

local secret(name) = kube.Secret(name) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/instance': 'renovate-runner',
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
    namespace: params.namespace.name,
  },
  stringData: {
    [s]: params.renovate[name].secrets[s]
    for s in std.objectFields(params.renovate[name].secrets)
  },
};

local cronjob(name) = kube.CronJob(name) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/instance': 'renovate-runner',
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
    namespace: params.namespace.name,
  },
  spec+: {
    schedule: params.renovate[name].schedule,
    failedJobsHistoryLimit: 3,
    successfulJobsHistoryLimit: 1,
    jobTemplate+: {
      metadata+: {
        labels+: {
          'app.kubernetes.io/instance': 'renovate-runner',
          'app.kubernetes.io/name': name,
        },
      },
      spec+: {
        template+: {
          metadata+: {
            labels+: {
              'app.kubernetes.io/instance': 'renovate-runner',
              'app.kubernetes.io/name': name,
            },
          },
          spec+: {
            containers_:: {
              default: {
                image: '%(registry)s/%(repository)s:%(tag)s' % params.images[params.renovate[name].type],
                imagePullPolicy: 'IfNotPresent',
                env: [
                  { name: 'RENOVATE_CONFIG_FILE', value: '/usr/src/app/config.json' },
                ],
                envFrom: [ { secretRef: { name: name } } ],
                volumeMounts: [
                  { name: 'config', mountPath: '/usr/src/app/config.json', subPath: 'config.json' },
                ],
              },
            },
            volumes_:: {
              config: { configMap: { name: name } },
            },
          },
        },
      },
    },
  },
};


// Define outputs below
{
  '00_namespace': namespace,
} + {
  ['10_' + name]: [
    config(name),
    secret(name),
    cronjob(name),
  ]
  for name in std.objectFields(params.renovate)
}
