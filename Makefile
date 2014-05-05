##
#include config.dmd

TARGET  = win32Dnd.exe
OBJS    = winMain.obj debugLog.obj drop_target.obj utils.obj \
				data_object.obj drop_source.obj enum_format.obj 

#RES     = resource.res

####
## http://gcc.gnu.org/onlinedocs/gcc/Invoking-GCC.html
CC      = gcc
CXX     = g++
CFLAGS  = -Wall -O2
CLDFLAGS =
CINCLUDES = -I/usr/local/include
CLIBS     = -L/usr/local/lib -lm

####
## http://dlang.org/dmd-windows.html
DMD     = dmd
DFLAGS = -g
#DFLAGS  = -O -release -inline -noboundscheck
DLDFLAGS = -L/SUBSYSTEM:WINDOWS:5.01
DMDLIBS  = lib/dmd_win32.lib

####
## http://www.digitalmars.com/ctg/sc.html
DMC      = dmc
DMCFLAGS = -HP99 -g -o+none -D_WIN32_WINNT=0x0400 -I$(SETUPHDIR) $(CPPFLAGS)
DMCLIB   = lib
DMCLIBFLAGS = lib -p512 -c -n

##---------------
# $@ : Target name
# $^ : depend Target name
# $< : Target Top Name
# $* : Target name with out suffix name
# $(MACRO:STING1=STRING2) : Replace STRING1 to STRING2
#
all : $(TARGET)

$(TARGET) : $(OBJS)
	$(DMD) $(OBJS) $(RES) $(DMDLIBS) $(DLDFLAGS) -of$@ 

#$(DTARGET) : $(SRC)
#	$(DMD) $(SRC) $(RES) $(DMDLIBS) $(DLDFLAGS) -of$@ 

test :
	$(TARGET)

clean :
	del *.obj
	del *.exe
	del *.bak
#	-rm -f $(TARGET) $(OBJS)

.c.obj :
	$(CC) $(CFLAGS) $(INCLUDES) -c $<

.d.obj :
	$(DMD) $(DFLAGS) -c $<

# Depend of header file
# obj : header
# foo.obj : foo.h 

