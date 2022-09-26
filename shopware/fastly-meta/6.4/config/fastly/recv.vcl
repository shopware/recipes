# Enable Fastly authentification for single purges
set req.http.Fastly-Purge-Requires-Auth = "1";

# Mitigate httpoxy application vulnerability, see: https://httpoxy.org/
unset req.http.Proxy;

# Strip query strings only needed by browser javascript. Customize to used tags.
if (req.url != req.url.path) {
  set req.url = querystring.filter(req.url,
    "pk_campaign" + querystring.filtersep() +
    "piwik_campaign" + querystring.filtersep() +
    "pk_kwd" + querystring.filtersep() +
    "piwik_kwd" + querystring.filtersep() +
    "pk_keyword" + querystring.filtersep() +
    "pixelId" + querystring.filtersep() +
    "kwid" + querystring.filtersep() +
    "kw" + querystring.filtersep() +
    "adid" + querystring.filtersep() +
    "chl" + querystring.filtersep() +
    "dv" + querystring.filtersep() +
    "nk" + querystring.filtersep() +
    "pa" + querystring.filtersep() +
    "camid" + querystring.filtersep() +
    "adgid" + querystring.filtersep() +
    "cx" + querystring.filtersep() +
    "ie" + querystring.filtersep() +
    "cof" + querystring.filtersep() +
    "siteurl" + querystring.filtersep() +
    "utm_source" + querystring.filtersep() +
    "utm_medium" + querystring.filtersep() +
    "utm_campaign" + querystring.filtersep() +
    "_ga" + querystring.filtersep() +
    "gclid"
    );
}

# Normalize query arguments
set req.url = querystring.sort(req.url);

# Make sure that the client ip is forward to the client.
if (req.http.x-forwarded-for) {
    set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
} else {
    set req.http.X-Forwarded-For = client.ip;
}

# Don't cache Authenticate & Authorization
if (req.http.Authenticate || req.http.Authorization) {
    return (pass);
}

# Always pass these paths directly to php without caching
# Note: virtual URLs might bypass this rule (e.g. /en/checkout)
if (req.url.path ~ "^/(checkout|account|admin|api|csrf)(/.*)?$") {
    return (pass);
}