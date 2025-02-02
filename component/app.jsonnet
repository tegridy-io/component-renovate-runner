local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.renovate_runner;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('renovate-runner', params.namespace.name);

local appPath =
  local project = std.get(std.get(app, 'spec', {}), 'project', 'syn');
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/renovate-runner' % appPath]: app,
}
