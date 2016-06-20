class ntp {
  package { ntp: }

  service { ntp:
    require => Package[ntp]
  }
}

class ntp::servers {
  $debian_ntp_servers = "0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org"
  $all_ntp_servers = $ntp_servers ? {
    '' => $debian_ntp_servers,
    default => $ntp_servers
  }
	$first_ntp_server = gsub($all_ntp_servers, "^([^ ]+).*", "\\1")
}

class ntp::client {
  include ntp
  include ntp::servers

  # very basic configuration ...
  # TODO use a local ntp server

  file { "/etc/ntp.conf":
    content => template("ntp/ntp-client.conf"),
    notify => Service[ntp]
  }

  include ntp::munin::client
}

class ntp::munin::client {
  include ntp::servers

	$munin_ntps = gsub(split($ntp::servers::all_ntp_servers, " "), "(.+)", "ntp_\\1")

	munin::plugin { $munin_ntps:
    source => "puppet:///modules/ntp/ntp_"
	}

  if $ntp::servers::all_ntp_servers != $ntp::servers::debian_ntp_servers {
    # Remove default ntp_ plugins
	  $munin_debian_ntps = gsub(split($ntp::servers::debian_ntp_servers, " "), "(.+)", "ntp_\\1")
	  munin::plugin { $munin_debian_ntps:
      ensure => absent
	  }
  }

}

class ntp::ntpdate {
  package { ntpdate: }

  if !$enable_ntpdate {
    file { "/etc/default/ntpdate":
      content => "exit 0\n"
    }
  }

  include ntp::ntpdate::tiger
}

class ntp::ntpdate::tiger {
  if $tiger_enabled {
    tiger::ignore { ntpdate: }
  }  
}


class ntp::munin::ntpdate {
  include ntp::servers
  include ntp::ntpdate

	munin::plugin { "ntpdate_$ntp::servers::first_ntp_server":
    source => "puppet:///modules/ntp/ntpdate_"
	}
}
