/++
 Win32 Drag and Drop demo 
class DataObject : ComObject, IDataObject
struct ObjectFormat

++/

module data_object;

import std.string;

import win32.shellapi;
import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import enum_format;
import utils;
import debugLog;

// DataObjct に格納するデータ形式は自由に定義できるようですが
// ファイルエクスプローラなど他のアプリケーションと DragDrop するにはデータ形式を同じに
// しないと当然できない

struct ObjectFormat
{
    FORMATETC _objfmt;
    STGMEDIUM _objmedium;
    
    void Set(FORMATETC pf, STGMEDIUM pm)
    {
        _objfmt = pf;
        _objmedium = pm;
    }

    bool Set(FORMATETC* pf, STGMEDIUM* pm, bool fRelease)
    {
        _objfmt = *pf;
        if (fRelease) {
            _objmedium = *pm;
            return	true;
        } else {
            return DuplicateMedium(&_objmedium, pf, pm);
        }
    }
    
    bool match(FORMATETC f)
    {
        bool result = false;
        if (_objfmt.tymed == f.tymed
            && _objfmt.cfFormat == f.cfFormat
            && _objfmt.dwAspect == f.dwAspect)
        {
            result = true;
        }
        return result;
    }
    
    bool DuplicateMedium(STGMEDIUM *pdest, FORMATETC* pf, STGMEDIUM *pm)
    {
        HANDLE	hVoid;
        
        switch (pm.tymed) {
        case TYMED.TYMED_HGLOBAL:
            hVoid = OleDuplicateData(cast(void*)pm.hGlobal, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.hGlobal = cast(HGLOBAL)hVoid;
            break;
        case TYMED.TYMED_GDI:
            hVoid = OleDuplicateData(cast(void*)pm.hBitmap, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.hBitmap = cast(HBITMAP)hVoid;
            break;
        case TYMED.TYMED_MFPICT:
            hVoid = OleDuplicateData(cast(void*)pm.hMetaFilePict, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.hMetaFilePict = cast(HMETAFILEPICT)hVoid;
            break;
        case TYMED.TYMED_ENHMF:
            hVoid = OleDuplicateData(cast(void*)pm.hEnhMetaFile, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.hEnhMetaFile = cast(HENHMETAFILE)hVoid;
            break;
        case TYMED.TYMED_FILE:
            hVoid = OleDuplicateData(cast(void*)pm.lpszFileName, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.lpszFileName = cast(LPOLESTR)hVoid;
            break;
        case TYMED.TYMED_NULL:
            hVoid = cast(HANDLE)1; //エラーにならないように
            break;
        case TYMED.TYMED_ISTREAM:
        case TYMED.TYMED_ISTORAGE:
        default:
            hVoid = null;
            break;
        }
        if (hVoid is null)
            return false;
        
        pdest.tymed = pm.tymed;
        pdest.pUnkForRelease = pm.pUnkForRelease;
        
        if (pm.pUnkForRelease !is null)
            pm.pUnkForRelease.AddRef();
        
        return true;
    }
}


class DataObject : ComObject, IDataObject
{
private:
    ObjectFormat[] _dataStores;

public:
    this() {}
    this(ObjectFormat[] of)
    {
           add(of);
    }
    this(FORMATETC pf, STGMEDIUM pm)
    {
        create(pf, pm);
    }
    ~this()
    {
        outLog("DataObject:~this");
    }
    
    void add(ObjectFormat[] of)
    {
        outLog("DataObject:Add");
        foreach (v; of)
            _dataStores ~= v;
    }
    
    void create(FORMATETC pf, STGMEDIUM pm)
    {
        outLog("DataObject:create");
        ObjectFormat fs;
        
        fs.Set(pf, pm);
        _dataStores ~= fs;
    }

    bool dropText(string text)
    {
        // FORMATETC fmtetc = { CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL };
        // STGMEDIUM stgmed = { TYMED.TYMED_HGLOBAL };
        FORMATETC fmtetc;
        STGMEDIUM stgmed;
        
        // HGLOBAL stgmed.hGlobal = CreateHText(text);
        HGLOBAL hObject = CreateHText(text);
        if (hObject == null) {
            return false;
        }
        SetupMedium(CF_TEXT, hObject, &fmtetc, &stgmed);
        create(fmtetc, stgmed);
        return true;
    }

    bool dropUnicodeText(string unitext)
    {
        FORMATETC fmtetc;
        STGMEDIUM stgmed;
        
        // HGLOBAL stgmed.hGlobal = CreateHText(text);
        HGLOBAL hObject = CreateUniText(unitext);
        if (hObject == null) {
            return false;
        }
        SetupMedium(CF_UNICODETEXT, hObject, &fmtetc, &stgmed);
        create(fmtetc, stgmed);
        return true;
    }

    bool dropFile(string[] filesList)
    {
        HDROP hObject = CreateHDrop(filesList);
        if (hObject == null) {
            outLog("hObject == null");
            return false;
        }
        
        FORMATETC fmtetc;
        STGMEDIUM stgmed;
        SetupMedium(CF_HDROP, hObject, &fmtetc, &stgmed);
        
        create(fmtetc, stgmed);
        return true;
    }

    void SetupMedium(CLIPFORMAT cfFormat, HANDLE hObject, FORMATETC *pf, STGMEDIUM *pm)
    {
        pf.cfFormat = cfFormat;
        pf.dwAspect = DVASPECT.DVASPECT_CONTENT;
        pf.lindex = -1;
        pf.ptd = NULL;
        pf.tymed = TYMED.TYMED_HGLOBAL;
  
        pm.hGlobal = hObject;
        pm.tymed = TYMED.TYMED_HGLOBAL;
        pm.pUnkForRelease = null;
  }


//@--------------------------------------------------------------------
    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        // outLog("DataObject:QueryInterface");
        if (*riid == IID_IDataObject)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        return super.QueryInterface(riid, ppv);
    }

//        Find the data of the format pFormatEtc and if found store
//        it into the storage medium pMedium.
//    
//        FORMATETC* pFormatEtc 指定されたデータと同じ物があったら
//        STGMEDIUM* pMedium に複製します
//
    extern (Windows)
    HRESULT GetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium)
    {
        outLog("DataObject:GetData");
        if (pFormatEtc is null || pMedium is null) {
            return E_INVALIDARG;
        }
        if (!(DVASPECT.DVASPECT_CONTENT & pFormatEtc.dwAspect))
            return DV_E_DVASPECT;
        
        // try to match the requested FORMATETC with one of our supported formats
        ObjectFormat fs;
        bool matchFlag;
        foreach (v ; _dataStores) {
            matchFlag = v.match(*pFormatEtc);
            if (matchFlag) {
                fs = v;
                break;
            }
        }
        if (matchFlag == false)
            return DV_E_FORMATETC;  // pFormatEtc is invalid
        
        // found a match - transfer the data into the supplied pMedium
        // store the type of the format, and the release callback (null).
        pMedium.tymed = fs._objfmt.tymed;
        pMedium.pUnkForRelease = null;
        
        // duplicate the memory
        switch (fs._objfmt.tymed) {
        case TYMED.TYMED_HGLOBAL:
            pMedium.hGlobal = dupGlobalMem(fs._objmedium.hGlobal);
            return S_OK;
            
        default:
            // todo: we should really assert here since we need to handle
            // all the data types in our formatStores if we accept them
            // in the constructor.
            return DV_E_FORMATETC;
        }
    }

    extern (Windows)
    HRESULT GetDataHere(FORMATETC* pFormatEtc, STGMEDIUM* pMedium)
    {
        outLog("DataObject:GetDataHere");
        // GetDataHere is only required for IStream and IStorage mediums
        // It is an error to call GetDataHere for things like HGLOBAL and other clipboard formats
        // OleFlushClipboard
        return DATA_E_FORMATETC;
    }

// Called to see if the IDataObject supports the specified format of data
//
// 指定された形式のデータが有るか無いかを返す関数です。
// データを返さない GetData です。
// DropTarget.QueryDataObject でも呼んでいます
//
    extern (Windows)
    HRESULT QueryGetData(FORMATETC* pf)
    {
        outLog("DataObject:QueryGetData");
        bool matchFlag;
        foreach (v ; _dataStores) {
            matchFlag = v.match(*pf);
            if (matchFlag) {
                break;
            }
        }
        return matchFlag ? S_OK : DV_E_FORMATETC;
    }


// MSDN: Provides a potentially different but logically equivalent
// FORMATETC structure. You use this method to determine whether two
// different FORMATETC structures would return the same data,
// removing the need for duplicate rendering.
//
    extern (Windows)
    HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatEtc, FORMATETC* pFormatEtcOut)
    {
        /*
            MSDN: For data objects that never provide device-specific renderings,
            the simplest implementation of this method is to copy the input
            FORMATETC to the output FORMATETC, store a NULL in the ptd member of
            the output FORMATETC, and return DATA_S_SAMEFORMATETC.
        */
        outLog("DataObject:GetCanonicalFormatEtc");
        *pFormatEtcOut = deepDupFormatEtc(*pFormatEtc);
        pFormatEtcOut.ptd = null;
        return DATA_S_SAMEFORMATETC;
    }

// データを追加する関数です。
// 配列の最後にデータを格納する
// 引数のBOOL fReleaseがFALSEの時はデータを複製して格納します。TRUEの時はそのまま格納します。
// fReleaseがTRUEの時はCDataObjectがデータを解放します。
// FALSEの時はSetDataを呼び出した側がちゃんと解放しないといけません。
//
    extern (Windows)
    HRESULT SetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium, BOOL fRelease)
    {
        outLog("DataObject:SetData");
//        return E_NOTIMPL;

        if (pFormatEtc is null || pMedium is null)
            return E_INVALIDARG;
        
        ObjectFormat fs;
        if (fs.Set(pFormatEtc, pMedium, fRelease == TRUE))
            return E_OUTOFMEMORY;
        
        _dataStores ~= fs;

        return S_OK;
    }

// Create and store an object into ppEnumFormatEtc which enumerates the
// formats supported by this DataObject instance.
//
    extern (Windows)
    HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppEnumFormatEtc)
    {
        outLog("DataObject:EnumFormatEtc");
        switch (dwDirection) {
        case DATADIR.DATADIR_GET:
        {
            if (_dataStores.length == 0 || ppEnumFormatEtc is null) {
                outLog("DataObject:EnumFormatEtc:E_INVALIDARG");
                return E_INVALIDARG;
            }
            
            FORMATETC[] fe;
            foreach (v ; _dataStores)
                fe ~= v._objfmt;
            
            outLog("fe.length=", fe.length);
            auto obj = new enum_format.EnumFormatEtc(fe);
            obj.AddRef();
            *ppEnumFormatEtc = obj;
            return S_OK;
        }
        
        // not supported for now.
        case DATADIR.DATADIR_SET:
            return E_NOTIMPL;
        default:
            assert(0, format("Unhandled direction case: %s", dwDirection));
        }
    }

    extern (Windows)
    HRESULT DAdvise(FORMATETC* pFormatEtc, DWORD advf, IAdviseSink* pAdvSink, DWORD* pdwConnection)
    {
        outLog("DataObject:DAdvise");
        return OLE_E_ADVISENOTSUPPORTED;
    }

    extern (Windows)
    HRESULT DUnadvise(DWORD dwConnection)
    {
        outLog("DataObject:DUnadvise");
        return OLE_E_ADVISENOTSUPPORTED;
    }

    extern (Windows)
    HRESULT EnumDAdvise(IEnumSTATDATA* ppEnumAdvise)
    {
        outLog("DataObject:EnumDAdvise");
        return OLE_E_ADVISENOTSUPPORTED;
    }
//@--------------------------------------------------------------------
}




