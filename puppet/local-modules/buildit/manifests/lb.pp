class buildit::lb (
    $app_nodes,
    ) {
   
    # ensure app_nodes is an array
    validate_array($app_nodes)

    # include the apache class
    class {'apache': 
        default_vhost => false,
    }

    # define a load balancer set
    apache::balancer { 'buildit': }

    # define balancer set members
    $app_nodes.each |$app_node| {
        apache::balancermember { "${app_node}-buildit":
            balancer_cluster => 'buildit',
            url              => "http://${app_node}:3000",
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
}
