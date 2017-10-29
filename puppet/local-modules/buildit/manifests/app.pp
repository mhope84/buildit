class buildit::app (
    $app_user,
    $app_group,
    $app_repo_url,
    $app_repo_revision,
    $app_directory = '/usr/local/nodeapp',
    $node_repo_package_name = 'nodesource-release-el7-1',
    $node_repo_package_url = 'https://rpm.nodesource.com/pub_6.x/el/7/x86_64/nodesource-release-el7-1.noarch.rpm',
    $node_package = 'nodejs',
    $systemd_template = 'buildit/nodejs-systemd',
    $systemd_unit_file = '/etc/systemd/system/buildit-app.service',
    $service_name = 'buildit-app',
    ) {

    # create app group
    group {$app_group:
        ensure => 'present',
    }

    # create app user
    user {$app_user:
        ensure  => 'present',
        gid     => $app_group,
        shell   => '/sbin/nologin',
        require => Group[$app_group],
    }

    # add nodejs YUM repo
    package { $node_repo_package_name:
        ensure   => 'installed',
        source   => $node_repo_package_url,
        provider => 'rpm',
    }

    # install nodejs
    package { $node_package:
        ensure  => 'installed',
        require => Package[$node_repo_package_name],
    }

    # check out the app code from git
    vcsrepo { $app_directory:
        ensure   => 'latest',
        provider => git,
        source   => $app_repo_url,
        revision => $app_repo_revision,
        require  => Package[$node_package],
    }

    # create a systemd unit file for the service
    file { $systemd_unit_file:
        content => template($systemd_template),
        owner   => 'root',
        group   => 'root',
        before  => Service[$service_name],
        require => Vcsrepo[$app_directory],
        notify  => [Exec['reload-systemd'], Service[$service_name]],
    }

    # reload systemd config to pickup new service unit
    exec { 'reload-systemd':
        command     => 'systemctl daemon-reload',
        refreshonly => true,
    }

    # start the service and ensure its set to start with the system
    service {$service_name:
        ensure  => 'running',
        enable  => 'true',
        require => File[$systemd_unit_file],
    }

}
