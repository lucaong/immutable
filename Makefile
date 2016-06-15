VERSION = $(shell crystal eval 'require "yaml"; s = YAML.parse(File.read("./shard.yml")); puts s["version"]')

docsite:
	crystal docs && git checkout gh-pages && mkdir -p api && cp -r doc/. api && git add api && git commit -m "generate docs" && git push && git checkout master

release:
	git fetch && git tag v$(VERSION) origin/master && git push origin v$(VERSION)
	open https://github.com/lucaong/immutable/releases/new?tag=v$(VERSION)

benchmark:
	mkdir -p ./tmp && crystal compile -o ./tmp/benchmarks --release ./benchmarks/benchmarks.cr
	./tmp/benchmarks
