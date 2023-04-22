# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   wault::put { 'namevar': }
define wault::put (
  $value,
  $path = $name,
) {
  $data = Deferred('wault::data',
    [$name, {
      path  => $path,
      value => $value
    }]
  )
  file { "/root/.wault.${md5($path)}.lock":
      content => Deferred('sprintf',['CENSORED', $data])
  }
}
