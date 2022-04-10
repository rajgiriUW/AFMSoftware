## Igor Software for controlling Asylum Research AFMs (e.g. MFP3D and Cypher systems)

### As used on the AFM in virtually 100% of the papers from the [Ginger Lab](http://depts.washington.edu/gingerlb/)

#### For information, the primary code maintainer:
```
Rajiv Giridharagopal, Ph.D.
University of Washington
Department of Chemistry
E: rgiri@uw.edu

[(My personal site](http://www.rajgiri.net)
[Ginger Lab](http://depts.washington.edu/gingerlb/)
```

This is the codebase for running the Asylum Research AFMs in our lab. This code is heavily-requested, but it is provided completely without any guarantees of it working or any other functionality. Indeed, you would have to do significant edits to have it run on your own systems, and it is built upon over 15 years of original legacy design.

I (Raj) am overwhelmingly the expert on this entire package.

##### Installation

1) Download this code to your computer
2) Open the Asylum AFM software and select a mode. We generally use the Standard Template mode, rather than pre-defined modes.
3) Highlight all of the .IPFs in the sub-folder "MFP3D-branch" or "Cypher-branch" and drag into the Igor software window
4) Hit "Compile" on the bottom left. A menu called "trEFM" should open at the top
