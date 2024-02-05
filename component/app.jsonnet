local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.renovate_runner;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('renovate-runner', params.namespace);

{
  'renovate-runner': app,
}
