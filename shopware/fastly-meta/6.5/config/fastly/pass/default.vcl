#official workaround to avoid the double X-Forwarded-Host when shielding is enabled
#https://www.fastly.com/documentation/reference/http/http-headers/X-Forwarded-Host/#overriding-multiple-entries
set bereq.http.X-Forwarded-Host = req.http.host; 

