# Don't allow clients to force a pass
if (req.restarts == 0) {
  unset req.http.x-pass;
}

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
    set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + req.http.Fastly-Client-IP;
} else {
    set req.http.X-Forwarded-For = req.http.Fastly-Client-IP;
}

# Don't cache Authenticate & Authorization
if (req.http.Authenticate || req.http.Authorization) {
    set req.http.x-pass = "1";
}

# Always pass these paths directly to php without caching
# Note: virtual URLs might bypass this rule (e.g. /en/checkout)
if (req.url.path ~ "^/(checkout|account|admin|api|csrf)(/.*)?$") {
    set req.http.x-pass = "1";
}

# Disable stale_while_revalidate feature on SHIELD node to avoid caching issue when both soft-purges and shieding are used.
if (fastly.ff.visits_this_service > 0) {
  set req.max_stale_while_revalidate = 0s;
}
