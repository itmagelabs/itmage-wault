#### Table of Contents

1. [Description](#description)
2. [Requirements](#setup)
3. [Usage, Configuration, and Examples](#usage)

## Description

For Puppet 6+ users wanting to use secrets from
[Hashicorp Vault](https://www.vaultproject.io/) on their Puppet agents, this
Puppet module provides the `wault::data()` function.

When used with Puppet 6's [`Deferred`
type](https://puppet.com/docs/puppet/7/deferring_functions.html), the function
allows agents to retrieve or put secrets for Vault when a catalog is applied rather
than compiled. In this way, the secret data is not embedded in the catalog and
the Puppetserver does not need permissions to read all your Vault secrets.

## Requirements

This modules assumes the following:
1. Puppet 6+
2. An existing [Vault](https://www.vaultproject.io/) infrastructure

The `wault::data()` function is expected to be run with the `Deferred`
type; as such, Puppet 6 or later is required.

And as this function is meant to read secrets from Vault, an existing Vault
infrastructure is assumed to be up and reachable by your Puppet agents.


## Usage

Install this module as you would in any other; the necessary code will
be distributed to Puppet agents via pluginsync.

In your manifests, call the `wault::data()` function using the
Deferred type. For example:

```puppet
file { '/tmp/password1':
  content => Deferred('wault::data',
    [
      'password1', { 'facts' => ['kernel'] }
    ]
  ),
}

file { '/tmp/password2':
  content => Deferred('wault::data',
    [
      'password2', {
        'facts'  => ['kernel', 'is_virtual'],
        'expire' => '1 week'
      }
    ]
  ),
}
```

### Configuring the Wault password

The lookup done by `wault::data()` can be configured in two ways:
a hash of options, configuration file.

In all cases, the path to the secret is the first positional argument and is
required. All other arguments are optional. Arguments in `[square brackets]`
below are optional.

#### Options Hash

```
wault::data( <name>, [<options_hash>] )
```


### Usage Examples

Here are some examples of each method:
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
