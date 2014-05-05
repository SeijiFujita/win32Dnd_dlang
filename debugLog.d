/++++
debugLog.d



++++/

module debugLog;

import std.stdio;
import core.vararg;
import std.ascii: isPrintable;
import std.string: format, lastIndexOf;
import std.file: append;
import std.datetime;
//
static int LogFlag;
static string debugLogFilename;

/++
enum logStatus {
	NON,
	LogOnly,
	WithConsole,
        abc,        
}
++/

void outLog(string file = __FILE__, int line = __LINE__, T...)(T t)
{
    // _outLogV(format("%s(%d)-[%s]", file, line, getDateTimeStr()), t);
    // for hidemaru  
    // _outLogV(format("%s(%d)[%s]", file, line, getDateTimeStr()), t);
    // for emacs
    _outLogV(format("%s:%d:[%s]", file, line, getDateTimeStr()), t);
}

// setDebugLog();
void setDebugLog(int flag = 1)
{
    enum string ext = "debug_log.txt";
    string logfilename;
    
    import core.runtime: Runtime;
    if (Runtime.args.length)
        logfilename = Runtime.args[0];
    
    debugLogFilename = ext;
    if (logfilename.length) {
        int n = lastIndexOf(logfilename, ".");
        if ( n > 0 )
            debugLogFilename = logfilename[0 .. n]  ~ "." ~ ext;
        else
            debugLogFilename =  logfilename ~ "." ~ ext;
    }
    LogFlag = flag;
    outLog(format("==debuglog %s", debugLogFilename));
}

static void _outLog(lazy string dg)
{
    if (LogFlag) {
        append(debugLogFilename, dg());
    }
}

static void _outLoglf(lazy string dg)
{
    if (LogFlag) {
        append(debugLogFilename, dg() ~ "\n");
    }
}

static void _outDebugLog(string s, lazy string dg)
{
    if (LogFlag) {
        string  sout = s ~ format("[%s]", getDateTimeStr()) ~ dg();
        append(debugLogFilename, sout ~ "\n");
        // writeln(debugLogFilename, sout);
        // stdout.writeln(sout);
    }
}

static void _outLogV(...)
{
    string str;
    for (int i = 0; i < _arguments.length; i++) {
        if (_arguments[i] == typeid(string)) {
            string s = va_arg!(string)(_argptr);
            str ~= format("%s", s);
        }
        else if (_arguments[i] == typeid(int)) {
            int n = va_arg!(int)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(uint)) {
            uint n = va_arg!(uint)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(short)) {
            short n = va_arg!(short)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(ushort)) {
            ushort n = va_arg!(ushort)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(long)) {
            long n = va_arg!(long)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(ulong)) {
            ulong n = va_arg!(ulong)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(char)) {
            char c = va_arg!(char)(_argptr);
            str ~= format("%c", c);
        }
        else if (_arguments[i] == typeid(wchar)) {
            wchar c = va_arg!(wchar)(_argptr);
            str ~= format("%c", c);
        }
        else if (_arguments[i] == typeid(dchar)) {
            dchar c = va_arg!(dchar)(_argptr);
            str ~= format("%c", c);
        }
        else if (_arguments[i] == typeid(byte)) {
            byte n = va_arg!(byte)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(ubyte)) {
            ubyte n = va_arg!(ubyte)(_argptr);
            str ~= format("%d", n);
        }
        else if (_arguments[i] == typeid(float)) {
            float f = va_arg!(float)(_argptr);
            str ~= format("%f", f);
        }
        else if (_arguments[i] == typeid(double)) {
            double d = va_arg!(double)(_argptr);
            str ~= format("%g", d);
        }
        else if (_arguments[i] == typeid(wstring)) {
            wstring s = va_arg!(wstring)(_argptr);
            str ~= format("%s", s);
        }
        else if (_arguments[i] == typeid(dstring)) {
            dstring s = va_arg!(dstring)(_argptr);
            str ~= format("%s", s);
        }
        else {
            assert(0, "Unknown type");
        }
    }
    _outLoglf(str);
}

static string getDateTimeStr()
{
    SysTime cTime = Clock.currTime();
    string  tms = format(
        "%04d/%02d/%02d-%02d:%02d:%02d", 
        cTime.year, 
        cTime.month, 
        cTime.day, 
        cTime.hour, 
        cTime.minute, 
        cTime.second); 
    return tms;
}

static string getDateStr()
{
    SysTime cTime = Clock.currTime();
    string  tms = format(
        "%04d/%02d/%02d", 
        cTime.year, 
        cTime.month, 
        cTime.day); 
    return tms;
}

void outdumpLog(string file = __FILE__, int line = __LINE__, T, U)(T t, U u)
{
    _outDebugLog(format("%s(%d)", file, line), format("dump:%d byte", u));
    _dumpLog(t, u);
}

static void _dumpLog(void *Buff, uint byteSize)
{
    const int PrintLen = 16;
    ubyte[PrintLen] dumpBuff;
    
    void printCount(uint n) {
        _outLog(format("%06d: ", n));
    }
    void printBody() {
        string s;
        foreach (int i, ubyte v; dumpBuff) {
            if (i == PrintLen / 2) {
                s ~= " ";
            }
            s ~= format("%02X ", v);
        }
        _outLog(s);
    }
    void printAscii() {
        string s;
        char c;
        foreach (ubyte v; dumpBuff) {
            c = cast(char)v;
            if (! isPrintable(c))
                c = '.';
            s ~= format("%c", c);
        }
        _outLoglf(s);
    }
    // Main
    uint endPrint;
    for (uint i; i < byteSize + PrintLen; i += PrintLen) {
        endPrint = i + PrintLen;
        if (byteSize < endPrint) {
            uint end = byteSize - i;
            dumpBuff = dumpBuff.init;
            dumpBuff[0 .. end] = cast(ubyte[]) Buff[i .. byteSize];
            printCount(i);
            printBody();
            printAscii();
            break;
        }
        dumpBuff = cast(ubyte[]) Buff[i .. endPrint];
        printCount(i);
        printBody();
        printAscii();
    }
}
//eof
