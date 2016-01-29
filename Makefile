docsite:
	crystal docs && git checkout gh-pages && cp -r doc/. . && git add . && git commit -m "generate docs" && git push && git checkout master
