#!/usr/bin/ruby
$CACHE_DIR = ENV['HOME'] + '/.domainfinder/'

# .org only allows 4 per minute
# .at is even stricter
min_server_delay = (ARGV[1] or 25).to_i

available_keywords = [
  ' - Available',
  'Domain Not Found',
  'Domain status:\s+available', # ca
  'NO MATCH for domain',
  'NOMATCH',
  'NOT FOUND',
  'No Data Found',
  'No Found', # tw
  'No Match for', # bz
  'No data found',
  'No entries found',
  'No information about domain',
  'No information available about domain name', # pl
  'No match',
  'No such domain',
  'Not Registered - ',
  'Not found',
  'Object_Not_Found', # mx
  'Status: Not Registered', # cm
  'Status:\s+AVAILABLE', # be
  'Status:\s+FREE',
  'Status:\s+available', # lt
  'Status:\s+free', # de
  'We do not have an entry in our database matching your query',
  '\" not found\.',
  'domain name not known', # tk
  'is free',
  'is not a valid domain name', # de
  'is not registered',
  'no entries found',
  'no matching record', # cn
  'not found in',
  'not found\.\.\.', # tc
  'nothing found',
  'Status:\s+Available', # gs
  'available for purchase', # sh, io

]

taken_keywords = [
  'Above domain name is not available', # kr
  'Admin-email', # sk
  'Administrative Contact:', #bz
  'Current Nameservers',
  'Domain ID:', # mobi
  'Domain Name ID', # au
  'Domain nameservers:',
  'Domain servers',
  'Domain status:\s+unavailable', # new ca
  'ERR - Nothing found',
  'Holder of domain name', # li
  'NS1-Hostname',
  'Name Server',
  'Name servers:',
  'Nameserver:',
  'Nameservers',
  'Not available',
  'Nserver:',
  'RESERVED NAME',
  'Record created on ',
  'Registered Date', #kr, generic
  'Registrant ID:', #so
  'Registrant Name: ', #cn
  'Status:\s+EXIST',
  'Status:\s+UNAV', # ca
  'Status:\s+QUARANTINE', #be
  'Status:\s+REGISTERED',
  'Tech ID:', # mobi
  'Technical Contact',
  'Technical contact:',
  'The domain you requested is in the reserved list', # cn
  '\[Tech-C\]', # de
  '\d\.\d+\.\d+\.\d+.*\w+\.\w+.*\d\d+\.\d+\.\d+\.\d', # to
  'dns_name',
  'domain_pri_ns:',
  'is in the queue for registration',
  'nameserver:',
  'nserver:',
  'registrant type:', # pl
  'registrant\'s handle:',
  'registrar:', # ru
  'reserved name', # tw
  'tech-c:', # lv
  'Status\s+:\s+Live', # io
]

$available_regexp = available_keywords.join('|')
$taken_regexp = taken_keywords.join('|')

if ARGV[0] == '-' then
  domains = $stdin.readlines
else
  domains = [ ARGV[0], ]
end

last_server_ts = {}



def determine_whois_server(full_domain)
  (domain, tld) = full_domain.split('.')
  # TODO: Read in a file like http://www.nirsoft.net/whois_servers_list.html

  whois_server = case tld
    when 'tc', 'tc', 'vg' then 'whois.adamsnames.tc'
    when 'bz' then 'whois.belizenic.bz'
    when 'cm' then 'whois.netcom.cm'
    when 'de' then 'whois.denic.de'
    when 'la','ly', 'lv', 'me', 'so' then 'whois.nic.' + tld
    else tld + '.whois-servers.net'
  end
  return whois_server
end

def whois(full_domain, whois_server)
  output = `whois -h #{whois_server} #{full_domain}`

  if output =~ /#{$available_regexp}/ && output =~ /#{$taken_regexp}/
    status='Unknown (matches both!)'
  elsif output =~ /#{$available_regexp}/
    status='Available'
  elsif output =~ /#{$taken_regexp}/
    status='Taken'
  elsif output =~ /Invalid characters|restricted from registration|To single out one record|Error for /i
    status='Invalid'
  else
    status='Unknown'
  end

  return status, output
end



domains.each do |next_domain|
  full_domain = next_domain.chomp
  cachefile = $CACHE_DIR + full_domain
  if File.exists?(cachefile)
    f = File.new(cachefile)
    status = f.readlines[0].chomp
    f.close
    cached = 1
  else
    cached = nil
    whois_server = determine_whois_server(full_domain)
    if last_server_ts[whois_server] and domains.length > 4
      difference = Time.now.to_i - last_server_ts[whois_server]
      if difference < min_server_delay then
        required_sleep = min_server_delay - difference
        sleep(required_sleep)
      end
    end
    (status, output) = whois(full_domain, whois_server)
    last_server_ts[whois_server] = Time.now.to_i

    # update cache
    if status != 'Unknown'
      f = File.new(cachefile, 'w')
      f.puts status
      f.close
    end
  end
  print "#{status}: #{full_domain}"
  if status == 'Unknown'
    print "\t\t# #{whois_server}: %s\n" % output.gsub(/[\r\n]/, '')
  else
    puts
  end
  $stdout.flush
end
