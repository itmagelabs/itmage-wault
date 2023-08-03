#### Table of Contents

1. [Description](#description)
2. [Examples](#examples)

## Description

For Puppet 6+ users wanting to use secrets from
[Hashicorp Vault](https://www.vaultproject.io/) on their Puppet agents, this
Puppet module provides the `wault::data()` function.

When used with Puppet 6's [`Deferred`
type](https://puppet.com/docs/puppet/7/deferring_functions.html), the function
allows agents to retrieve or put secrets for Vault when a catalog is applied rather
than compiled. In this way, the secret data is not embedded in the catalog and
the Puppetserver does not need permissions to read all your Vault secrets.

## Examples

### Configuring the Wault password

The lookup done by `wault::data()` can be configured in two ways:
a hash of options, configuration file.

In all cases, the path to the secret is the first positional argument and is
required. All other arguments are optional. Arguments in `[square brackets]`
below are optional.

#### Options Hash

```
wault::data( <name>, [<OPTIONS HASH>>] )
```

An options hash can have the following keys:

Option|Default|Description
:------|:-------:|:-----------
facts |'__common'|
expire |''|
path       |nil|
namespace  |nil|
config_dir |'/opt/wault'|
config_file|'/opt/wault/.vault.yaml'|
address    |'http://127.0.0.1:8200'|
token      |<secret>|
ssl_verify |false|
timeout    |30|
force      |false|

```puppet
# Running a function on a agent node
$out = Deferred('wault::data',
  [ 'example', {
      'facts'  => ['kernel', 'is_virtual'],
      'expire' => '1 week'
    } ]
)

#  If you need to put a value in a string
$out = Deferred('wault::data',[
    'my_parameter_in_vault', {'facts' => ['kernel']}
])
file { '/etc/config.env':
    ensure  => file,
    content => Deferred('sprintf',['PARAMETER=%s', $out])
}

# Running a function on a server node
$password = wault::data('example')
$other_password = wault::data('other',
  {
    'facts'  => ['kernel', 'is_virtual'],
    'expire' => '1 week'
  }
)
```
