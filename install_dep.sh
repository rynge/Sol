#!/bin/sh

#zlib
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/zlib-1.2.8.tar.gz
tar xzf zlib-1.2.8.tar.gz
cd zlib-1.2.8
./configure --prefix=$HOME
make check install
cd ..

#hdf5
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/hdf5-1.8.9.tar.gz
tar xzf hdf5-1.8.9.tar.gz
cd hdf5-1.8.9
./configure --with-zlib=$HOME --prefix=$HOME
make check install
cd ..

#netcdf
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.3.2.tar.gz
tar xzf netcdf-4.3.2.tar.gz
cd netcdf-4.3.2
CPPFLAGS=-I${HOME}/include LDFLAGS=-L${HOME}/lib ./configure --prefix=$HOME
make check install
cd ..

#PROJ.4
wget http://download.osgeo.org/proj/proj-4.8.0.tar.gz
wget http://download.osgeo.org/proj/proj-datumgrid-1.5.tar.gz
tar xzf proj-4.8.0.tar.gz
cd proj-4.8.0/nad
tar xzf ../../proj-datumgrid-1.5.tar.gz
cd ..
./configure --prefix=$HOME
make
make install
cd ..

#gdal
wget http://download.osgeo.org/gdal/1.11.1/gdal-1.11.1.tar.gz
tar xzf gdal-1.11.1.tar.gz
cd gdal-1.11.1
./configure --without-grass --with-netcdf=$HOME -with-python --prefix=$HOME
make
make install
cd ..

#geos
wget http://download.osgeo.org/geos/geos-3.4.2.tar.bz2
tar -xjf geos-3.4.2.tar.bz2
cd geos-3.4.2
./configure --prefix=$HOME --enable-python
make
make install
cd ..


export LD_LIBRARY_PATH=$HOME/lib

#GRASS
wget http://grass.osgeo.org/grass64/source/grass-6.4.4.tar.gz
tar xzf grass-6.4.4.tar.gz
cd grass-6.4.4
 CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME --with-proj-lib=$HOME/lib --with-proj-share=${HOME}/share/proj/ --with-proj-includes=$HOME/include --with-gdal=$HOME  --with-cxx --without-fftw --without-python --with-geos=${HOME}/bin --with-libs=$HOME/lib
make
make install
cd ..

#GDAL_GRASS
wget http://download.osgeo.org/gdal/gdal-grass-1.4.3.tar.gz
tar xzf gdal-grass-1.4.3.tar.gz
./configure --with-gdal=$HOME/bin/gdal-config --with-grass=$HOME/grass-6.4.4/ --prefix=$HOME
make
make install

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/grass-6.4.4/lib


#iCommands
wget http://www.iplantcollaborative.org/sites/default/files/irods/icommands.x86_64.tar.bz2
tar -xjf icommands.x86_64.tar.bz2
export PATH=${PATH}:$HOME/icommands

export PYTHONPATH=${PYTHONPATH}:$HOME/cctools/python2.6/site-packages
