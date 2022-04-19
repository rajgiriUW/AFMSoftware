## Igor Software for controlling Asylum Research AFMs (e.g. MFP3D and Cypher systems)

### As used on the AFM in most of the papers from the [Ginger Lab](http://depts.washington.edu/gingerlb/)

### For information, the primary code maintainer:
```
Rajiv Giridharagopal, Ph.D.
University of Washington
Department of Chemistry
E: rgiri@uw.edu
```

This is the codebase for running the Asylum Research AFMs in our lab. This code is heavily-requested, but it is **provided completely without any guarantees of it working or any other functionality.** Indeed, you would have to do significant edits to have it run on your own systems, and it is built upon over 15 years of original legacy design. This will likely have many compile errors looking for a missing XOP or two, but contact me for specific workarounds. Most of those can be commented out.

I (Raj) am overwhelmingly the expert and lead on this entire package.

Again: **use at your own risk!!!** 

### Installation

1) Download this code to your computer
2) Open the Asylum AFM software and select a mode. We generally use the Standard Template mode, rather than pre-defined modes.
3) Highlight all of the .IPFs in the sub-folder "MFP3D-branch" or "Cypher-branch" and drag into the Igor software window
4) Hit "Compile" on the bottom left. A menu called "trEFM" should open at the top

This software involves a lot of references to Gage XOP, which is used to interface with a Dynamic Signals brand "Gage" Digitizer card used primarily by our lab in time-resolved electrostatic force microscopy work. It is similar, if more powerful and significantly more compact, than typical NI digitizers used in other labs. There is a repo for the C++ code; however, it require the Igor Pro SDK to function. If you need more information, please contact me.

### Documentation

[Documentation](https://htmlpreview.github.io/?https://github.com/rajgiriUW/AFMSoftware/blob/master/sphinx_documentation/_build/html/index.html)
Thanks to Linda Taing for all the hard work over the years.

There is a lot of documentation of functions (but not that much in the way of a user guide) in the subfolder "sphinx_documentation" when you download the package, under ```_build/html```


Please ask me any questions.

### Contributors

This AFM software was largely the brainchild of David Ginger and David Coffey from the early-00s. Since then, the code has been significantly rewritten in many ways, primarily to keep up with changes in the Asylum code as well as changes in Igor Pro.

A brief list of past Ginger Lab members that have contributed significantly to this work aside from myself (if anyone listed here wishes to be removed, please let me know):
* David Ginger
* David Coffey
* Obadiah Reid
* Liam Pingree
* Guozheng Shao
* David Moore
* Jeff Harrison
* David Moerman

### Other links:
* [My personal site](http://www.rajgiri.net)
* [Ginger Lab](http://depts.washington.edu/gingerlb/)
