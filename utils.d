/++
 Win32 Drag and Drop demo 

++/

module utils;

import core.atomic;
import core.memory;
import core.stdc.string;

import std.file;
import std.string;

import win32.shellapi;
import win32.shlobj;
import win32.winnls;
import win32.objidl;
import win32.ole2;
import win32.wtypes;
import win32.winbase;
import win32.windef;

import debugLog;

//@----------------------------------------------------------------------------
int cPtrLen(const char *s)
{
    char *src;
    if (s is null)
        return 0;
    src = cast(char*)s;
    while (1) {
        if (*src == '\0')
            break;
        
        src++;
    }
    return src - s;
}

void cPtrCopy(ref char[] dest, const char *src)
{
    uint n = cPtrLen(src);
    dest[0 .. n] = src[0 .. n];
}

// char * to string
string cPtrToString(const char *s)
//string cPtrToString(char *s)
{
    char[] str;
    uint len = cPtrLen(s);
    if (len == 0)
        return "";
    
    str.length = len;
    cPtrCopy(cast(char[])str, s);
    return cast(string)str;
    // return s ? s[0 .. strlen(s)] : cast(string)null;
}
//@----------------------------------------------------------------------------
/**
   Create a global memory buffer and store text contents to it.
   Return the handle to the memory buffer.
*/
HGLOBAL toGlobalMem(string text)
{
    outLog("toGlobalMem:text", text);
    // allocate and lock a global memory buffer. Make it fixed
    // data so we don't have to use GlobalLock
    // char* ptr = cast(char*)GlobalAlloc(GMEM_FIXED, text.memSizeOf);
    char* ptr = cast(char*)GlobalAlloc(GHND, text.memSizeOf);
    
    // copy the string into the buffer
    ptr[0 .. text.length] = text[];
    
    deepHG ~= ptr;
    showMMgr();
    return cast(HGLOBAL)ptr;
}

/** Return the memory size needed to store the elements of the array. */
size_t memSizeOf(E)(E[] arr)
{
    return E.sizeof * arr.length;
}

///
unittest
{
    int[] arrInt = [1, 2, 3, 4];
    assert(arrInt.memSizeOf == 4 * int.sizeof);
    
    long[] arrLong = [1, 2, 3, 4];
    assert(arrLong.memSizeOf == 4 * long.sizeof);
}

/**
   Duplicate the memory helt at the global memory handle,
   and return the handle to the duplicated memory.
*/
HGLOBAL dupGlobalMem(HGLOBAL hMem)
{
    outLog("dupGlobalMem");
    // lock the source memory object
    PVOID source = GlobalLock(hMem);
    scope(exit) GlobalUnlock(hMem);
    
    // create a fixed global block - just
    // a regular lump of our process heap
    DWORD len = GlobalSize(hMem);
    PVOID dest = GlobalAlloc(GMEM_FIXED, len);
    memcpy(dest, source, len);
    
    deepHG ~= dest;
    showMMgr();
    
    return dest;
}

//@----------------------------------------------------------------------------
// debugs
void*[] deepHG;

void showMMgr()
{
    outLog("deepHG.length=", deepHG.length);
    foreach (i, v ; deepHG) {
        outLog("deepHG[", i, "]:", v is null ? "null" : "use");
  }
}
void cleanMMgr()
{
    foreach (v ; deepHG) {
        if (v !is null) {
            GlobalFree(v);
        }
    }
    deepHG.length = 0;
}

//@----------------------------------------------------------------------------
/** Perform a deep copy of a FORMATETC structure. */
FORMATETC deepDupFormatEtc(FORMATETC source)
{
    FORMATETC res;
    res = source;
    
    outLog("deepDupFormatEtc");
    
    // duplicate memory for the DVTARGETDEVICE if necessary
    if (source.ptd)
    {
        res.ptd = cast(DVTARGETDEVICE*)CoTaskMemAlloc(DVTARGETDEVICE.sizeof);
        *(res.ptd) = *(source.ptd);
    }
    return res;
}

//@----------------------------------------------------------------------------

abstract class ComObject : IUnknown
{
    shared(LONG) _refCount;
    
    HRESULT QueryInterface(IID* riid, void** ppv)
    {
        if (*riid == IID_IUnknown)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        *ppv = null;
        return E_NOINTERFACE;
    }

    ULONG AddRef()
    {
        LONG lRef = atomicOp!"+="(_refCount, 1);
        
        outLog("ComObject:AddRef:lRef:", cast(long)lRef);
        
        if (lRef == 1) {
            GC.addRoot(cast(void*)this);
        }
        return lRef;
    }

    ULONG Release()
    {
        LONG lRef = atomicOp!"-="(_refCount, 1);
        
        outLog("ComObject:Release:lRef:", cast(long)lRef);
        
        if (lRef == 0) {
            GC.removeRoot(cast(void*)this);
        }
        return cast(ULONG)lRef;
    }
}  // ComObject


string[] getFiles(string path)
{
    bool extMatch(string path, string ext) {
        if (path[$ - ext.length .. $] == ext) {
            return true;
        }
        return false;
    }
    
    string[] files;
    foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
        if (e.isFile() && extMatch(e.name, ".d")) {
            files ~= e.name;
        }
    }
    return files;
}

//@----------------------------------------------------------------------------
HGLOBAL CreateHText(string text)
{
    HGLOBAL	hText;
    
    // int len = MultiByteToWideChar(CP_ACP, 0, text.toStringz(), -1, null, 0);
    hText = GlobalAlloc(GHND, text.length + 1);
    // hText = GlobalAlloc(GHND, len);
    if (hText is null)
        return null;
    
    char*  buf = cast(char*) GlobalLock(hText);
    // MultiByteToWideChar(CP_UTF8, 0, text.toStringz(), -1, buf, len);
    buf[0 .. text.length] = text[];
    buf[text.length] = '\0';
    
    deepHG ~= buf;
    showMMgr();
    
    GlobalUnlock(hText);
    
    return hText;
}
HGLOBAL CreateUniText(string text)
{
    HGLOBAL	hText;
    
    int len = MultiByteToWideChar(CP_UTF8, 0, text.toStringz(), -1, null, 0) * wchar.sizeof;
    hText = GlobalAlloc(GHND, len + 1);
    if (hText is null)
        return null;
    
    wchar *buf = cast(wchar*) GlobalLock(hText);
    MultiByteToWideChar(CP_UTF8, 0, text.toStringz(), -1, buf, len);
    
    deepHG ~= buf;
    showMMgr();
    
    GlobalUnlock(hText);
    return hText;
}

/++
struct DROPFILES {
	DWORD pFiles;
	POINT pt;
	BOOL fNC;
	BOOL fWide;
}
alias DROPFILES* LPDROPFILES;
++/
HDROP CreateHDrop(string[] filesPath)
{
    HDROP hDrop;
    int btotal = 0;
    int ucount = 0;

    foreach (i ; 0 .. filesPath.length) {
        btotal += MultiByteToWideChar(CP_UTF8, 0, filesPath[i].toStringz(), -1, null, 0) * wchar.sizeof;
    }
    hDrop = cast(HDROP)GlobalAlloc(GHND, DROPFILES.sizeof + btotal + 2);
    if (hDrop is null)
        return null;
    
    deepHG ~= hDrop;
    showMMgr();
    
    LPDROPFILES lpDropFile;
    lpDropFile  = cast(LPDROPFILES) GlobalLock(hDrop);
    lpDropFile.pFiles = DROPFILES.sizeof;
    lpDropFile.pt.x   = 0;
    lpDropFile.pt.y   = 0;
    lpDropFile.fNC    = false;
    // lpDropFile.fWide  = false;					/* ワイドキャラの場合は TRUE */
    lpDropFile.fWide  = true;					/* ワイドキャラの場合は TRUE */
    
    // 構造体の後ろにファイル名のリストをコピーする。(filename\0filename\0filename\0\0\0)
    wchar *buf = cast(wchar *) &lpDropFile[1];
    //  outLog("filesPath:");
    int count;
    foreach (i ; 0 .. filesPath.length) {
        //	outLog(filesPath[i]);
        //	buf += stringCopy(buf, filesPath[i]) + 1;
        count = MultiByteToWideChar(CP_UTF8, 0, filesPath[i].toStringz(), -1, buf, btotal);
        //		outLog("count:", count);
        buf	+= count;
        //    btotal -= count;
    }
    *buf++ = 0;
    *buf = 0;
    
    GlobalUnlock(hDrop);
    
    return hDrop;
}


int stringCopy(char *dest, string src)
{
    dest[0 .. src.length] = src[];
    dest[src.length] = '\0';
    return src.length;
}

// eof
