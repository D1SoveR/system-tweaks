/* PAC file for connecting to mullvad SOCKS5 proxy */

function FindProxyForURL(url, host) {

    // Most straighforward case - we're dealing with single-word names,
    // or anything on .local domain, it has to be in the local network
    if (
        isPlainHostName(host) ||
        dnsDomainIs(host, ".local") ||
        dnsDomainIs(host, ".d1sover-pc")
    ) {
        return "DIRECT";
    }

    // Check if we're accessing any local network by IP range
    if (
        isInNet(host, "192.168.0.0", "255.255.0.0") ||
        isInNet(host, "172.16.0.0",  "255.240.0.0") ||
        isInNet(host, "10.0.0.0",    "255.0.0.0")
    ) {
        return "DIRECT";
    }

    var domainExceptions = [

        // Netflix exceptions
        // Netflix dislikes VPNs, so we route their requests directly, so that we can watch it
        // without the VPN turned on (but without having to disable PAC setup in the browser)
        ["netflix.com", "nflxext.com", "nflximg.net", "nflxso.net", "nflxvideo.net"],

        // OpenNIC exceptions
        // OpenNIC-domain'd locations don't seem to play too well with Mullvad's SOCKS proxy,
        // so we'll be bypassing the proxy for these top-level domains as well
        [".bbs", ".cyb", ".dyn", ".epic", ".geek", ".indy", ".libre", ".neo", ".null", ".o", ".oss", ".parody", ".pirate"]

    ];

    if (domainExceptions.some(function(domainList) {
        return domainList.some(function(domain) { return dnsDomainIs(host, domain); });
    })) {
        return "DIRECT";
    }

    return "SOCKS5 10.64.0.1:1080";

}
