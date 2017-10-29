class buildit::lb (
    $app_nodes,
    ) {
   
    # ensure app_nodes is an array
    validate_array($app_nodes)

    # include the apache class and ensure its default vhost is not deployed
    class {'apache': 
        default_vhost => false,
    }

    # define a load balancer set
    apache::balancer { 'buildit': 
        proxy_set => { 'lbmethod' => 'bytraffic' },
    }

    # define balancer set members
    $app_nodes.each |$app_node| {
        apache::balancermember { "${app_node}-buildit":
            balancer_cluster => 'buildit',
            url              => "${app_node}",
        }
    }

    # create load balancer vhost
    class { 'apache::vhosts':
        vhosts => {
            'buildit_vhost' => {
                'docroot' => '/var/www/html',
                'port'    => '80',
                'proxy_pass' => [ {'path' => '/', 'url' => 'balancer://buildit' } ]
            },
        },
    }

    # allow access to HTTP from the public zone
    firewalld_service { 'Allow Access to HTTP from the public zone':
        ensure  => 'present',
        service => 'http',
        zone    => 'public',
    }
}
