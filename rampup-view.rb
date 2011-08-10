#!/usr/bin/env ruby

require 'net/http'
require 'uri'

host = ARGV[0]

n = (ARGV[1] || "1000").to_i
s = k = 0

for x in 0..n
  a = Time.now
  uri = URI.parse("http://#{host}:5984/default/_design/rampup/_view/random?startkey=#{k}&limit=10&stale=ok")
  Net::HTTP.new(uri.host, uri.port).start {|http|
    http.request_get(uri.request_uri)
    http.finish
  }
  b = Time.now
  s = s + (b - a)
  k = k + 1
  k = 0 if k >= 100
end

print "requests #{n}\n"
print "time #{s}\n"
print "req/sec #{n / s}\n"

