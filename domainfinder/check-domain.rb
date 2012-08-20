#!/usr/bin/ruby
$CACHE_DIR = ENV['HOME'] + '/.domainfinder/'

# .org only allows 4 per minute
min_server_delay = (ARGV[1] or 20).to_i

available_keywords = [
  ' - Available',
  'Not found',
  '\" not found\.',
  'We do not have an entry in our database matching your query',
  'Not Registered - ',
  'no entries found',
  'No entries found',
  'is free',
  'No information about domain',
  'is not registered',
  'nothing found',
  'not found in',
  'No match',
  'NOT FOUND',
  'Status:             AVAILABLE',
  'Status:      FREE',
  'NOMATCH',
  'No Data Found',
  'No data found',
  'No such domain',
  'Domain Not Found',
  'Status:			available', #lt
  'NO MATCH for domain',
  'No Found', # tw
  'is not a valid domain name', # de
  'Status:         AVAIL', # ca
  'no matching record', # cn
  'Not found:', # so
]

taken_keywords = [
  'Status:         EXIST',
  'Status:      QUARANTINE', #be
  'NS1-Hostname',
  'Name Server',
  'Status:      REGISTERED',
  'Nameservers',
  'RESERVED NAME',
  'Domain nameservers:',
  'registrant\'s handle:',
  'dns_name',
  'Record created on ',
  'Name servers:',
  'Current Nameservers',
  'nameserver:',
  'Registered Date', #kr, generic
  'Technical Contact',
  'Not available',
  'domain_pri_ns:',
  'is in the queue for registration',
  'Nameserver:',
  'registrar:', # ru
  'Nserver:',
  'Admin-email', # sk
  'Above domain name is not available', # kr
  'Technical contact:',
  'nserver:',
  'Domain servers',
  'Registrant Name: ', #cn
  'The domain you requested is in the reserved list', # cn
  'reserved name', # tw
  'tech-c:', # lv
  'Tech ID:', # mobi
  'Domain ID:', # mobi
  'Tech-C', # de
  'ERR - Nothing found',
  'Domain Name ID', # au
  'Holder of domain name', # li
  'Status:         UNAV', # ca
  '\d\.\d+\.\d+\.\d+.*\w+\.\w+.*\d\d+\.\d+\.\d+\.\d', # to
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
  whois_server = case tld
    when 'tc','ms','vg' then 'whois.adamsnames.tc'
    when 'la','ly', 'lv', 'so' then 'whois.nic.' + tld
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
  if status == 'Unknown':
    print "\t# %-90.90s\n" % output.gsub(/[\r\n]/, '')
  else
    puts
  end
  $stdout.flush  
end
