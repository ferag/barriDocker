FROM indigodatacloud/ubuntu-sshd:16.04

MAINTAINER Fernando Aguilar <aguilarf@ifca.unican.es>

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install subversion libtool libltdl7 libltdl-dev libexpat1-dev gcc gfortran g++ mpich byacc flex openssl ruby libreadline6-dev libnetcdf-dev autoconf automake autotools-dev make wget uuid-dev && \
    rm -rf /var/lib/apt/lists/* 

RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.0.tar.gz && \
    tar -zxvf netcdf-4.4.0.tar.gz && \
    rm netcdf-4.4.0.tar.gz

RUN cd netcdf-4.4.0 && ./configure --disable-netcdf-4 --prefix=/usr && make && make install

RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-4.4.3.tar.gz && \
    tar -zxvf netcdf-fortran-4.4.3.tar.gz && \
    rm netcdf-fortran-4.4.3.tar.gz
    
RUN cd netcdf-fortran-4.4.3 && ./configure --disable-netcdf-4 --prefix=/usr && make && make install

ENV NETCDF_LIBS -I/usr/lib
ENV NETCDF_CFLAGS -I/usr/include

RUN svn checkout https://svn.oss.deltares.nl/repos/delft3d/tags/delft3d4/7545/src delft3d_repository/src --username ferag.x --password indigo && \
    sed -i "s/addpath PATH \/opt\/mpich2-1.4.1-gcc-4.6.2\/bin/addpath PATH \/usr\/bin/" delft3d_repository/src/build.sh && \
    sed -i "s/export MPI_INCLUDE=\/opt\/mpich2-1.4.1-gcc-4.6.2\/include/export MPI_INCLUDE=\/usr\/include/" delft3d_repository/src/build.sh && \
    sed -i "s/export MPILIBS_ADDITIONAL=\"-L\/opt\/mpich2-1.4.1-gcc-4.6.2\/lib -lfmpich -lmpich -lmpl\"/export MPILIBS_ADDITIONAL=\"-L\/usr\/lib -lfmpich -lmpich -lmpl\"/" delft3d_repository/src/build.sh && \
    sed -i "s/export MPIFC=\/opt\/mpich2-1.4.1-gcc-4.6.2\/bin\/mpif90/export MPIFC=\/usr\/bin\/mpif90/" delft3d_repository/src/build.sh && \
    sed -i "s/addpath PATH \/opt\/gcc\/bin/addpath PATH \/usr\/bin/" delft3d_repository/src/build.sh && \
    sed -i "s/addpath LD_LIBRARY_PATH \/opt\/gcc\/lib \/opt\/gcc\/lib64/addpath LD_LIBRARY_PATH \usr\/lib \/usr\/lib64/" delft3d_repository/src/build.sh && \
    sed -i "s/make ds-install &> \$log/make ds-install/" delft3d_repository/src/build.sh && \
    sed -i "s/-lfmpich -lmpich -lmpl/-lmpich -lmpl/" delft3d_repository/src/build.sh && \ 
    cat delft3d_repository/src/build.sh | grep ds-install && \
    delft3d_repository/src/build.sh -gnu -64bit -debug && \
    ls /delft3d_repository/src/engines_gpl/waq/default/ > ls.txt && \
    cp /delft3d_repository/src/engines_gpl/waq/default/* /delft3d_repository/bin/lnx64/waq/default/

RUN exec 3<> /etc/apt/sources.list.d/onedata.list && \
    echo "deb [arch=amd64] http://packages.onedata.org/apt/ubuntu/1902 xenial main" >&3 && \
    echo "deb-src [arch=amd64] http://packages.onedata.org/apt/ubuntu/1902 xenial main" >&3 && \
    exec 3>&-
RUN apt-get update
RUN apt-get install sudo oneclient curl --allow-unauthenticated -y
