# Consider Shopware http cache cookies
if (req.http.sw-cache-hash) {
  set req.hash += req.http.sw-cache-hash;
} elseif (req.http.cookie:sw-currency) {
  set req.hash += req.http.cookie:sw-currency;
}