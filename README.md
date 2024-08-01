# RPM builder for HAProxy 3.0 (CentOS 8/9)
## Build latest HAProxy binary with prometheus metrics support

![GitHub last commit](https://img.shields.io/github/last-commit/philyuchkoff/HAProxy-3-RPM-builder?style=for-the-badge)
![GitHub All Releases](https://img.shields.io/github/downloads/philyuchkoff/HAProxy-3-RPM-builder/total?style=for-the-badge)


### [HAProxy](http://www.haproxy.org/) 3.0.3 2024/07/11

Perform the following steps on a build box as a regular user:

    sudo dnf -y groupinstall 'Development Tools'
    cd /opt
    sudo git clone https://github.com/philyuchkoff/HAProxy-3-RPM-builder.git
    cd ./HAProxy-2-RPM-builder

### Build:

#### Without Lua:

    sudo make
    
#### With Lua:

    sudo make USE_LUA=1

#### With Prometheus module:

    sudo make USE_PROMETHEUS=1

#### Without sudo for YUM:

    sudo make NO_SUDO=1

Resulting RPM will be stored in 

    /opt/HAProxy-3-RPM-builder/rpmbuild/RPMS/x86_64/

#### Build using Docker:

    sudo make run-docker

Resulting RPM will be stored in 

    ./RPMS/


### Install:

    sudo dnf -y install /opt/HAProxy-3-RPM-builder/rpmbuild/RPMS/x86_64/haproxy-3.0.3-1.el8.x86_64.rpm

or, if you build *.rpm with Docker:

    sudo yum -y install RPMS/haproxy-3.0.3-1.el8.x86_64.rpm 
    

### Check after install:

    haproxy -v

### Stats page

After installation you can access a stats page **without** authenticating via the URL: `http://<YourHAProxyServer>:9000/haproxy_stats`



### Common problem:

#### :o: If some not working - check SELINUX:

    sestatus

If SELINUX is enabled  - switch off this: open /etc/selinux/config and change SELINUX to disabled:

    sudo sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config


#### :o: Cannot chroot1
    [/usr/sbin/haproxy.main()] Cannot chroot1(/var/lib/haproxy)  
##### Solution:
- Create `/var/lib/haproxy` directory
- Check on the rpcbind service to ensure that this service is started 

#### :o: Failed to download metadata for repo ‘AppStream’ (CentOS8/9)
##### Solution:
    cd /etc/yum.repos.d/
    sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
    sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
