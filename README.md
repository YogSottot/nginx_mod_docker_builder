# nginx_mod_docker_builder
https://github.com/evanmiller/mod_zip  
https://github.com/gabihodoroaga/nginx-ntlm-module  
https://github.com/tokers/zstd-nginx-module  

A set of dockerfiles and scripts to build a zip / ntlm / zstd module for nginx. 
To build, run ```debian-12.sh``` or ```ubuntu-24.04.sh``` script.  
Modules will be built for standard versions of nginx from the distributions own repositories.  

For ```debian-12``` — ```nginx 1.22.1```  
For ```debian-13``` — ```nginx 1.26.3```  
For ```ubuntu 24.04``` — ```nginx 1.24.0```  

The result of building is placed in the directory ```fpm/${mod_name}/${os_version}```  


Copy the module to the server in the ```/etc/nginx/modules-available/``` directory and place the ```50-mod-*.conf``` file in ```/etc/nginx/modules-enabled```
or install deb packages from ```fpm/deb``` or setup repo with this packages https://yogsottot.github.io/ppa/  

For building you need fpm  
```
gem install --no-document --user-install fpm
```
