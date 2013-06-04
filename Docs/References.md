References
==========

##Wikipedia

* [EPub](http://en.wikipedia.org/wiki/EPUB)

##StackOverflow

* [Develop ePub file reader in iOS 5](http://stackoverflow.com/questions/11933874/develop-epub-file-reader-in-ios-5)
* [Reading ePub format](http://stackoverflow.com/questions/1388467/reading-epub-format)

##International Digital Publishing Forum

* [Epub](http://idpf.org/epub)

##Github

* [AnFengDe / EPUB_SDK](https://github.com/AnFengDe/EPUB_SDK)


##Others

* [Epub Format Construction Guide](http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html)



===

# Process

1. unzip
2. parse manifest file (container.xml)
	* /META-INF/container.xml
	* in container.xml, there is a path to "opf" file (content.opf)
3. parse opf file (content.opf)
	* Basic information (titile language author subject…)
	* items (html page, images, stylesheet, toc)
	* itemrefer (the id of html page in items, the chapter)
	* guide
	
4. parse toc.ncx
	* the table of contents/ title of each chapter
	
5. webview show html
	* image ? included?
	* paging, Now, fix scrollview, change offset when changing page
	