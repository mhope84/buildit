class buildit (
    $app_node = 'false',
    $lb_node  = 'false',
    ) {


    # if this is an app node include the code to handle it
    if (str2bool($app_node)) {
        include buildit::app
    }
 
    # if this is a load balancer node include the code to handle it
    if (str2bool($lb_node)) {
        include buildit::lb
    }

}
