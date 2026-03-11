#!/bin/bash
set -e
echo "Build Clash core"

cd ClashX/goClash
python3 build_clash_universal.py
cd ../..

echo "Pod install"
bundle install --jobs 4
bundle exec pod install
echo "delete old files"
rm -f ./ClashX/Resources/Country.mmdb
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
gzip Country.mmdb
mv Country.mmdb.gz ./ClashX/Resources/Country.mmdb.gz
echo "install dashboard"
cd ClashX/Resources
# Clone dashboard from MetaCubeX/Yacd-meta (replaces defunct Dreamacro/clash-dashboard)
if ! git clone --depth 1 -b gh-pages https://github.com/MetaCubeX/Yacd-meta.git dashboard 2>/dev/null; then
    echo "Warning: Failed to clone dashboard, creating placeholder"
    mkdir -p dashboard
    echo "<html><body><h1>Dashboard not available</h1></body></html>" > dashboard/index.html
fi

if [ -d "dashboard/.git" ]; then
    cd dashboard
    rm -rf manifest.webmanifest CNAME .git
    cd ..
fi

# Fix hardcoded API URL in dashboard to auto-detect from window.location
if [ -f "dashboard/index.html" ]; then
    sed -i '' 's|<div id="app" data-base-url="http://127.0.0.1:9090"></div>|<div id="app"></div>\n    <script>\n      // Auto-detect API URL from current page location\n      const appDiv = document.getElementById('\''app'\'');\n      const baseUrl = window.location.origin;\n      appDiv.setAttribute('\''data-base-url'\'', baseUrl);\n    </script>\n|' dashboard/index.html
fi
cd ../..
