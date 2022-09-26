# remove set cookie headers to make responses cachable
if (beresp.http.cache-control ~ "public") {
  unset beresp.http.set-cookie;

  return (deliver);
}

return (pass);