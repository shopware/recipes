# Remove the exact PHP Version from the response for more security (e.g. 404 pages)
unset resp.http.x-powered-by;

# We use fastly.ff.visits_this_service to avoid running this logic on shield nodes. We only need to
# run it on edge nodes
if (fastly.ff.visits_this_service == 0 && resp.http.sw-invalidation-states) {
  # invalidation headers are only for internal use
  unset resp.http.sw-invalidation-states;

  ## we don't want the client to cache
  set resp.http.Cache-Control = "no-cache, private";
}
