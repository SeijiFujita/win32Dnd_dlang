/++
 Win32 Drag and Drop demo 
 enum_format.d

++/


module enum_format;

import core.atomic;
import core.memory;


import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import utils;
import debugLog;

class EnumFormatEtc : ComObject, IEnumFORMATETC
{
private:
    uint _index;
    FORMATETC[] _formatEtc;

public:
    //
    this(FORMATETC[] fmt)
    {
        outLog("EnumFormatEtc:this");
        _index = 0;
        foreach (v ; fmt)
            _formatEtc ~= deepDupFormatEtc(v);
    }
    ~this()
    {
        outLog("EnumFormatEtc:~this");
    }
    //
    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        outLog("EnumFormatEtc:QueryInterface");
        if (*riid == IID_IEnumFORMATETC)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        return super.QueryInterface(riid, ppv);
    }
    /**
        MSDN: If the returned FORMATETC structure contains a non-null
        ptd member, then the caller must free this using CoTaskMemFree.
        
        itemCount で指定された数だけFORMATETC構造体を pf にコピーします。
    **/
    extern (Windows)
    HRESULT Next(ULONG itemCount, FORMATETC* pf, ULONG* itemsCopied)
    {
        outLog("ClassEnumFormatEtc:Next");
        if (itemCount <= 0 || pf is null || _index >= _formatEtc.length)
            return S_FALSE;
        
        // itemCount が1 の時だけitemsCopied はNULLに出来る?
        if (itemCount != 1 && itemsCopied is null )
            return S_FALSE;
        
        if (itemsCopied != null)
            *itemsCopied = 0;
        
        ULONG copyCount = 0;
        while (_index < _formatEtc.length && copyCount < itemCount)
        {
            pf[copyCount] = deepDupFormatEtc(_formatEtc[_index]);
            copyCount++;
            _index++;
        }
        if (itemsCopied != null)
            *itemsCopied = copyCount;
        // did we copy all that was requested?
        return copyCount == itemCount ? S_OK : S_FALSE;
    }
    
/++
    extern (Windows)
    HRESULT Skip(ULONG itemCount)
    {
        outLog("ClassEnumFormatEtc:Skip");
        _index += itemCount;
        return _index <= _formatEtc.length ? S_OK : S_FALSE;
    }
++/
    // 読みとり位置(_index)をitemCount分スキップします
    extern (Windows)
    HRESULT Skip(ULONG itemCount)
    {
        outLog("ClassEnumFormatEtc:Skip");
        
        while(_index < _formatEtc.length && itemCount > 0) {
            _index++;
            itemCount--;
        }
        return (itemCount == 0)? S_OK : S_FALSE;
    }
    
    // 読みとり位置(_index)を先頭に戻します
    extern (Windows)
    HRESULT Reset()
    {
        outLog("ClassEnumFormatEtc:Reset");
        _index = 0;
        return S_OK;
    }
    
    // Clone this enumerator.
    // ppEnumFormatEtc を複製します
    extern (Windows)
    HRESULT Clone(IEnumFORMATETC* ppEnumFormatEtc)
    {
        outLog("ClassEnumFormatEtc:Clone");
        if (_formatEtc.length == 0 || ppEnumFormatEtc is null)
            return E_INVALIDARG;
        
        auto obj = new EnumFormatEtc(_formatEtc);
        if (obj is null)
            return E_OUTOFMEMORY;
        
        obj.AddRef();
        *ppEnumFormatEtc = obj;
        return S_OK;
    }

private:
    private void releaseMemory()
    {
        outLog("releaseMemory");
        foreach (v ; _formatEtc) {
            if (v.ptd)
                CoTaskMemFree(v.ptd);
        }
    }
}
// eof
