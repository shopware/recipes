# Pass immediately if x-pass is present
if (req.http.x-pass) {
  return (pass);
}

# remove set cookie headers to make responses cachable
if (beresp.http.cache-control ~ "public") {
  unset beresp.http.set-cookie;
}

if (beresp.http.Cache-Control ~ "private|no-cache|no-store") {
  set req.http.Fastly-Cachetype = "PRIVATE";
  return (pass);
}

# If the object is coming with no Expires, Surrogate-Control or Cache-Control headers we assume it's a misconfiguration
# and should not cache it. This is to prevent inadventently caching private data
if (!beresp.http.Expires && !beresp.http.Surrogate-Control ~ "max-age" && !beresp.http.Cache-Control ~ "(s-maxage|max-age)") {
  # Varnish sets default TTL if none of the headers above are present. If not set we want to make sure we don't cache it
        set beresp.ttl = 3600s;
        return(pass);
}
