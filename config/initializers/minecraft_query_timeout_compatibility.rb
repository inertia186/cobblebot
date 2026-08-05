# minecraft-query 1.0.0 calls `timeout` from Query's singleton methods. Ruby 3
# no longer exposes that helper there implicitly, so provide Timeout's module
# function as a singleton method until the dependency is updated.
require 'minecraft-query'

Query.extend(Timeout) unless Query.respond_to?(:timeout, true)
