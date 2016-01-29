docsite:
	crystal docs && git checkout gh-pages && mkdir -p api && cp -r doc/. api && git add . && git commit -m "generate docs" && git push && git checkout master
