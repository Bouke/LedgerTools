build:
	-rm -r .build/debug/CLI* # fix spaces build bug
	swift build -Xcc -I`brew --prefix`/opt/libcsv/include -Xlinker -L`brew --prefix`/opt/libcsv/lib

clean:
	-rm -r .build
