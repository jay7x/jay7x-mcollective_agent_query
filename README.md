# mcollective_agent_query version 1.0.0

#### Table of Contents

1. [Overview](#overview)
1. [Usage](#usage)
1. [Configuration](#configuration)

## Overview

Query data from various network sources

The mcollective_agent_query module is generated automatically, based on the source from https://github.com/jay7x/jay7x-mcollective_agent_query

Available Actions and their arguments:

  * **exporter** - Returns Prometheus exporter metrics requested
    * `url`
    * `metrics`
  * **rest** - Returns REST API reply
    * `url`
    * `method`
    * `headers`
    * `data`

## Usage

You can include this module into your infrastructure as any other module, but as it's designed to work with the [choria mcollective](http://forge.puppet.com/choria/mcollective) module you can configure it via Hiera:

```yaml
mcollective::plugin_classes:
  - mcollective_agent_query
```

### How to use the agent via CLI

This agent was designed primarily to use in a playbook. Though you may try to use it via `mco rpc query (exporter|rest)` call. It's impossible to pass array on input at the moment. So please use JSON file as input then.

### How to use the agent in a playbook

You can use this task as any other Choria tasks. Please refer to [Choria.io docs](https://choria.io/docs/playbooks/tasks/) for more info.

`query.exporter` example:
```
$res = choria::task(
  action     => 'query.exporter',
  nodes      => ['node1.tld', 'node2.tld'],
  properties => {
    url     => 'http://127.0.0.1:9419/metrics',
    metrics => [ 'rabbitmq_running' ],
  },
)
```

`query.rest` example:
```
$res = choria::task(
  action     => 'query.rest',
  nodes      => ['node1.tld', 'node2.tld'],
  properties => {
    url     => 'http://localhost:8080/api/v1/list',
    method  => 'GET',
    headers => {},
    data    => '',
  },
)
```

## Configuration

Server and Client configuration can be added via Hiera and managed through tiers in your site Hiera, they will be merged with any included in this module

```yaml
mcollective_agent_query::config:
   example: value
```

This will be added to both the `client.cfg` and `server.cfg`, you can likewise configure server and client specific settings using `mcollective_agent_query::client_config` and `mcollective_agent_query::server_config`.

These settings will be added to the `/etc/puppetlabs/mcollective/plugin.d/` directory in individual files.

For a full list of possible configuration settings see the module [source repository documentation](https://github.com/jay7x/jay7x-mcollective_agent_query).

## Data Reference

  * `mcollective_agent_query::gem_dependencies` - Deep Merged Hash of gem name and version this module depends on
  * `mcollective_agent_query::manage_gem_dependencies` - disable managing of gem dependencies
  * `mcollective_agent_query::package_dependencies` - Deep Merged Hash of package name and version this module depends on
  * `mcollective_agent_query::manage_package_dependencies` - disable managing of packages dependencies
  * `mcollective_agent_query::class_dependencies` - Array of classes to include when installing this module
  * `mcollective_agent_query::package_dependencies` - disable managing of class dependencies
  * `mcollective_agent_query::config` - Deep Merged Hash of common config items for this module
  * `mcollective_agent_query::server_config` - Deep Merged Hash of config items specific to managed nodes
  * `mcollective_agent_query::client_config` - Deep Merged Hash of config items specific to client nodes
  * `mcollective_agent_query::policy_default` - `allow` or `deny`
  * `mcollective_agent_query::policies` - List of `actionpolicy` policies to deploy with an agent
  * `mcollective_agent_query::client` - installs client files when true - defaults to `$mcollective::client`
  * `mcollective_agent_query::server` - installs server files when true - defaults to `$mcollective::server`
  * `mcollective_agent_query::ensure` - `present` or `absent`

## Development:

To contribute to this [Choria.IO](https://choria.io) plugin please visit https://github.com/jay7x/jay7x-mcollective_agent_query

This module was generated using the Choria Plugin Packager based on templates found at the [GitHub Project](https://github.com/choria-io/).
