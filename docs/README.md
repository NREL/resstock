# Documentation Setup

## Install Prerequisites

 - [Python 2.7](https://www.python.org/downloads/)
 - [Node JS](https://nodejs.org/en/download/)

If you are on a Mac and using [Homebrew](https://brew.sh/) (recommended), you can install both easily by

```
brew install node
brew install python
```

## Install Sphinx

Sphinx is what turns our documentation source into html or a pdf. 

```
pip install sphinx
pip install sphinx_rtd_theme
```

Change that to `pip2` if you installed python from Homebrew.

## Install Grunt

Included with the documentation is an automated task runner that will do a few useful things.

1. Run sphinx to build an HTML version of the documentation
2. Open/refresh a browser tab that previews the documentation HTML
3. Repeat 1 and 2 each time changes are made to the documentation source files (\*.rst, \*.py, and any file in ./images and ./examples)

The task runner uses [Grunt](http://gruntjs.com), and for Grunt to work properly on your computer, you'll need to install a few prerequisites and do some configuration on your local repository.

`cd` into this documentation directory. Run the command:

```
npm install -g grunt-cli
```

Finally, install the prerequisites for the specific Grunt file for the documentation.

```
npm install
```

## Run the task runner

When you're working on the docs run the following command from the docs directory.

```
grunt
```

This will compile the HTML documentation and open a new browser tab to see the built version of the docs.
As you make changes and save them, it will update and refresh the preview. When you're done, do a `Ctrl-C`
in the grunt window to stop Grunt.