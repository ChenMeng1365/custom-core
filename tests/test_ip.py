''' match-patterns '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# No need to refer

import re, IPy

def ipv4_addr_check(ipAddr):
    p = re.compile('^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$')
    if p.match(ipAddr): return True
    return False

def ipv6_addr_check(ipAddr):
    p = re.compile(r'^(((:|[0-9a-fA-F]{0,4}):)([0-9a-fA-F]{0,4}:){0,5}((([0-9a-fA-F]{0,4}:)?(:|[0-9a-fA-F]{0,4}))|(((25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9]))))$')
    if p.match(ipAddr): return True
    return False

def ipv4_mask_process(address_cidr):
    if not address_cidr: return None
    ip = IPy.IP(address_cidr, make_net=1)
    src_net = ip.strNetmask().split('.')
    return ip.strFullsize(0) , '.'.join(src_net)

def ipv6_mask_process(address_cidr):
    if not address_cidr: return None
    src_ip = IPy.IP(address_cidr, make_net=1)
    return src_ip.strFullsize(0), src_ip.prefixlen()

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
