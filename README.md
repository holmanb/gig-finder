gigfinder
==========

*A perl utility for finding job opportunities*

gigfinder is a simple tool - you give it it job search profiles, and it sends them to you. By default it runs as a process once, but by default it will only send you links to jobs that you have not yet been sent


Installation 
------------

This program should be straightforward to run and work with once dependencies are installed.  I've created a prototype installer script for debian based systems. If it fails, take a looks at 
the error messages to figure out why, if you find and error, or would like to submit a pull request for a more versatile installer, please do.  There are a handful of perl modules required, and the installer uses *cpanm*, as well as ssnmtp and mailutils which must be configured and setup to be able to send email via command line.
	
	$ git clone https://github.com/holmanbph/gig-finder.git

	$ sudo bash gig-finder/install.sh


Configuration
-------------

This script uses YAML files to search for jobs matching each profile.  By default, all configuration files stored under the /config directory will be used as inputs for the program.  
Arguments can changes this behaviour to target other config files or directories of config files.  Each configuration file allows the user to define multiple email destinations, 
websites to parse, and keywords to search for or avoid. The example YAML file can be used as a template for a search profile, and can be duplicated to create multiple profiles. The 
configuration format YAML is fairly intuitive for configurations like this. For someone using this for the first-time, be warned that tabs cannot be used in yaml, only spaces are allowed.   
	
	

Runtime Options
---------------

OPTIONS

	-c, --clear_cache: 			clears the history of previus jobs sent. This literally just deleates .cache

	-p, --past: 				prints out cached jobs (that have been previously sent)

	-d, --dry_run: 				intended for use with the installer, but can be used with cache options

	-n, --no_email: 			runs to completion, but skips sending an email

	-f FILE, --file=FILE: 			specify a custom config file 

	-l DIRECTORY, --location=DIRECTORY: 	specify a custom config directory location

	-h, --help:  				help instructions


EXAMPLES

	./gigfinder -h | less

	./gigfinder -c  -n

				 


Contributing
------------

1. Fork this repository.
2. Create a branch (`git checkout -b my_gigfinder`)
3. Commit your changes (`git commit -am "Added feature or bugfix XXX"`)
4. Push to the branch (`git push origin my_gigfinder`)
5. Create a pull request and link to any associated bugs or feature requests 
6. Wait


AUTHOR
------
	Written by Brett Holman in Fall 2017.

