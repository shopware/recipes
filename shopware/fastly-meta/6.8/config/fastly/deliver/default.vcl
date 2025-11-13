# Remove the exact PHP Version from the response for more security (e.g. 404 pages)
unset resp.http.x-powered-by;
