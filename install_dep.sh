#!/bin/sh

#python 2.7
wget http://python.org/ftp/python/2.7.2/Python-2.7.2.tar.bz2
cd Python-2.7.2
./configure --prefix=$HOME/ --enable-unicode=ucs4
make
make install

#swig
wget http://prdownloads.sourceforge.net/swig/swig-3.0.5.tar.gz
tar xzf swig-3.0.5.tar.gz
cd swig-3.0.5
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.35.tar.gz
./Tools/pcre-build.sh
./configure --prefix=$HOME
make install

#zlib
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/zlib-1.2.8.tar.gz
tar xzf zlib-1.2.8.tar.gz
cd zlib-1.2.8
./configure --prefix=$HOME
make install
cd ..

#hdf5
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/hdf5-1.8.9.tar.gz
tar xzf hdf5-1.8.9.tar.gz
cd hdf5-1.8.9
./configure --with-zlib=$HOME --prefix=$HOME
make check install
cd ..

#netcdf
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.3.3.tar.gz
tar xzf netcdf-4.3.3.tar.gz
cd netcdf-4.3.3
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
./configure --without-grass --with-netcdf=$HOME -with-python --prefix=$HOME --with-hdf5=$HOME
make
make install
cd ..

export PATH=${PATH}:$HOME/bin

#geos
wget http://download.osgeo.org/geos/geos-3.4.2.tar.bz2
tar -xjf geos-3.4.2.tar.bz2
cd geos-3.4.2
./configure --prefix=$HOME --enable-python
make
make install
cd ..


export LD_LIBRARY_PATH=$HOME/lib

#Flex
wget http://downloads.sourceforge.net/project/flex/flex-2.5.39.tar.gz
tar xzf flex-2.5.39.tar.gz
cd flex-2.5.39
./configure --prefix=$HOME
make install
cd ..

#Bison
wget http://ftp.gnu.org/gnu/bison/bison-3.0.tar.gz
tar xzf bison-3.0.tar.gz
cd bison-3.0
./configure --prefix=$HOME
make install
cd ..

#libtiff
wget ftp://ftp.remotesensing.org/pub/libtiff/tiff-4.0.3.tar.gz
tar xzf tiff-4.0.3.tar.gz
cd tiff-4.0.3
./configure --prefix=$HOME
make install
cd ..

#libpng
wget ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.17.tar.gz
tar xzf libpng-1.6.17.tar.gz
cd libpng-1.6.17
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#SQLite
wget https://www.sqlite.org/2015/sqlite-autoconf-3080900.tar.gz
tar xzf sqlite-autoconf-3080900.tar.gz
cd sqlite-autoconf-3080900
./configure --prefix=$HOME
make install 
cd ..

#OpenGL/Mesa-Utils
#######################

#######################

#FreeType
wget http://download.savannah.gnu.org/releases/freetype/freetype-2.5.5.tar.gz
tar xzf freetype-2.5.5.tar.gz
cd freetype-2.5.5
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make 
make install
cd ..
#PKD-Config
wget http://pkgconfig.freedesktop.org/releases/pkgconfig-0.18.tar.gz
tar xzf pkgconfig-0.18.tar.gz
cd pkgconfig-0.18
./configure --prefix=$HOME
make install
cd ..

#Pixman
wget http://cairographics.org/releases/pixman-0.32.6.tar.gz
tar xzf pixman-0.32.6.tar.gz
cd pixman-0.32.6
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install 
cd ..

#Cairo
wget http://cairographics.org/releases/cairo-1.12.0.tar.gz
tar xzf cairo-1.12.0.tar.gz
cd cairo-1.12.0
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#libffi
wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
tar xf libffi-3.2.1.tar.gz
cd libffi-3.2.1
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#GetText
wget http://ftp.gnu.org/pub/gnu/gettext/gettext-latest.tar.gz
tar xf gettext-latest.tar.gz
cd gettext-latest
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install 
cd ..

#GLib
wget ftp://ftp.gnome.org/pub/gnome/sources/glib/2.44/glib-2.44.0.tar.xz
tar xf glib-2.44.0.tar.xz
cd glib-2.44.0
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#ATK
wget http://ftp.gnome.org/pub/gnome/sources/atk/2.16/atk-2.16.0.tar.xz
tar xf atk-2.16.0.tar.xz
cd atk-2.16.0
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#Pango
wget ftp://ftp.gnome.org/pub/gnome/sources/pango/1.36/pango-1.36.8.tar.xz

#GTK+
wget http://ftp.gnome.org/pub/gnome/sources/gtk+/3.14/gtk+-3.14.13.tar.xz
tar xf gtk+-3.14.13.tar.xz
cd gtk+-3.14.13
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#wxPython
wget http://downloads.sourceforge.net/wxpython/wxPython-src-3.0.2.0.tar.bz2
tar xjf wxPython-src-3.0.2.0.tar.bz2
cd wxPython-src-3.0.2.0
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME
make install
cd ..

#GRASS
wget http://grass.osgeo.org/grass64/source/grass-6.4.4.tar.gz
tar xzf grass-6.4.4.tar.gz
cd grass-6.4.4
CPPFLAGS="-I${HOME}/include" LDFLAGS="-L${HOME}/lib" ./configure --prefix=$HOME --with-proj-lib=$HOME/lib --with-proj-share=${HOME}/share/proj/ --with-proj-includes=$HOME/include --with-gdal=$HOME  --with-cxx --without-fftw --without-python --with-geos=${HOME}/bin --with-libs=$HOME/lib -with-opengl=no --with-freetype-includes=$HOME/include/freetype2 --with-netcdf
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

#cctools
wget http://www3.nd.edu/~ccl/software/files/cctools-4.3az-source.tar.gz
tar -xf cctools-4.3az-source.tar.gz
cd cctools-4.3az-source
