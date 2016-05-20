build:
	-rm -r .build/debug/CLI* # fix spaces build bug
	swift build

clean:
	-rm -r .build
