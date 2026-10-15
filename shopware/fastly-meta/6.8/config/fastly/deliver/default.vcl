# Remove the exact PHP Version from the response for more security (e.g. 404 pages)
unset resp.http.x-powered-by;

# Apply the asset policy to cached and uncached responses alike.
if (req.url.path ~ "^/(media|thumbnail|theme|bundles)/") {
  set resp.http.Content-Security-Policy = "script-src 'none'; object-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'";
}
