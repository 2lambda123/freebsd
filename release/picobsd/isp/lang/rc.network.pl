#!/bin/sh -
# $Id: rc.network.pl,v 1.1.1.1 1998/08/27 17:38:42 abial Exp $
network_pass1() {
    echo -n 'Wstepna konfiguracja sieci:'
    # Set the host name if it is not already set
    if [ -z "`hostname -s`" ] ; then
	    hostname $hostname
	    echo ' hostname'
    fi
    # Set up all the network interfaces, calling startup scripts if needed
    for ifn in ${network_interfaces}; do
	    if [ -e /etc/start_if.${ifn} ]; then
		    . /etc/start_if.${ifn}
	    fi
	    # Do the primary ifconfig if specified
	    eval ifconfig_args=\$ifconfig_${ifn}
	    if [ -n "${ifconfig_args}" ] ; then
		    ifconfig ${ifn} ${ifconfig_args}
	    fi
	    # Check to see if aliases need to be added
	    alias=0
	    while :
	    do
		    eval ifconfig_args=\$ifconfig_${ifn}_alias${alias}
		    if [ -n "${ifconfig_args}" ]; then
			    ifconfig ${ifn} ${ifconfig_args} alias
			    alias=`expr ${alias} + 1`
		    else
			    break;
		    fi
	    done
	    ifconfig ${ifn}
    done
    # Load the filters if required
    if [ -n "$firewall_enable" -a -f /etc/rc.firewall -a \
    	"x$firewall_enable" = "xYES" ] ; then
    		. /etc/rc.firewall
    		echo "Zaladowano reguly filtrujace do firewalla."
    else
	    echo "UWAGA: system posiada wbudowany modul firewalla, ale zadne reguly"
	    echo "       filtrujace nie zostaly zaladowane."
	    echo "       Wszystkie rodzaje ruchu IP sa dozwolone."
    fi
    # Configure routing
    if [ "x$defaultrouter" != "xNO" ] ; then
	    static_routes="default ${static_routes}"
	    route_default="default ${defaultrouter}"
    fi
    # Set up any static routes.  This should be done before router discovery.
    if [ "x${static_routes}" != "x" ]; then
	    for i in ${static_routes}; do
		    eval route_args=\$route_${i}
		    route add ${route_args}
	    done
    fi
    echo -n 'Dodatkowe opcje routingu:'
    if [ -n "$tcp_extensions" -a "x$tcp_extensions" != "xYES" ] ; then
	    echo -n ' tcp_extensions=NO'
	    sysctl -w net.inet.tcp.rfc1323=0 >/dev/null 2>&1
	    sysctl -w net.inet.tcp.rfc1644=0 >/dev/null 2>&1
    fi
    if [ "X$gateway_enable" = X"YES" ]; then
	    echo -n ' IP_gateway=YES'
	    sysctl -w net.inet.ip.forwarding=1 >/dev/null 2>&1
    fi
    if [ "X$arpproxy_all" = X"YES" ]; then
	    echo -n ' wlaczam ARP_PROXY_ALL: '
	    sysctl -w net.link.ether.inet.proxyall=1 2>&1
    fi
    echo '.'
    network_pass1_done=YES	# Let future generations know we made it.
}

network_pass2() {
    network_pass2_done=YES
}

network_pass3() {
    network_pass3_done=YES
}
