# nginx_mod_zip_docker_builder
https://github.com/evanmiller/mod_zip  

A set of dockerfiles and scripts to build a zip module for nginx. 
To build, run ```debian-12.sh``` or ```ubuntu-24.04.sh``` script.  
Modules will be built for standard versions of nginx from the distributions own repositories.  

For ```debian-12``` — ```nginx 1.22.1```  
For ```ubuntu 24.04``` — ```nginx 1.24.0```  

The result of building ```ngx_http_zip_module.so``` is placed in the directory ```module_ubuntu-24.04.sh```
 or ```module_debian12.sh```  

Copy the module to the server in the ```/etc/nginx/modules-available/``` directory and place the ```50-mod-http-zip.conf``` file in ```/etc/nginx/modules-enabled```
