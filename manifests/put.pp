# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   wault::put { 'namevar': }
define wault::put (
  Optional $value = undef,
  $path = $name,
) {
  $defaults = {path => $path}
  if $value {
    $params = {value => $value}
  } else { $params = {} }
  $data = Deferred('wault::data',
    [$name, merge($params, $defaults)]
  )
  file { "/root/.wault.${md5($path)}.lock":
      content => Deferred('sprintf',['CENSORED', $data])
  }
}
