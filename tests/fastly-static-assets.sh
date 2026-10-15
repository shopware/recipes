#!/bin/sh
set -eu

# This exercises the deliver snippets in Varnish; Fastly must still validate its own dialect.
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
policy="script-src 'none'; object-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'"

for snippet in shopware/fastly-meta/*/config/fastly/deliver/default.vcl; do
    test_file=$test_dir/static-assets.vtc
    {
        echo "varnishtest \"Asset policy: $snippet\""
        echo 'server s1 {'
        for status in 200 200 200 200 200 200 200 200 200 200 404; do
            echo 'rxreq'
            echo "txresp -status $status -hdr \"Cache-Control: public, max-age=3600\" -hdr \"Content-Security-Policy: default-src 'self'\" -body response"
        done
        echo '} -start'
        echo 'varnish v1 -vcl+backend {'
        echo 'sub vcl_deliver {'
        # Adapt only Fastly-specific variables; keep the complete deliver logic.
        sed -e 's/req.url.path/regsub(req.url, "[?].*$", "")/g' \
            -e 's/fastly.ff.visits_this_service/0/g' "$snippet"
        echo '}'
        echo '} -start'
        echo 'client c1 {'
        for path in /media/test.html /media/test.html /thumbnail/test.svg /theme/app.js /bundles/app/index.html /media/image.png /media/no-extension /media/test.html?download=1 /admin /application/rendered.html /media-other/test.html /media/missing.html; do
            expected_policy=$policy
            case "$path" in
                /admin|/application/*|/media-other/*) expected_policy="default-src 'self'" ;;
            esac
            status=200
            [ "$path" != /media/missing.html ] || status=404
            echo "txreq -url \"$path\""
            echo 'rxresp'
            echo "expect resp.status == $status"
            echo "expect resp.http.Content-Security-Policy == \"$expected_policy\""
        done
        echo '} -run'
        echo 'varnish v1 -expect MAIN.cache_hit == 1'
    } > "$test_file"
    varnishtest "$test_file"
done
