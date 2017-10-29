class buildit (
    $app_node = 'false',
    $lb_node  = 'false',
    ) {
  
    # set global path for any exec's
    Exec {
        path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    }

    # if this is an app node include the code to handle it
    if (str2bool($app_node)) {
        include buildit::app
    }
 
    # if this is a load balancer node include the code to handle it
    if (str2bool($lb_node)) {
        include buildit::lb
    }

}
