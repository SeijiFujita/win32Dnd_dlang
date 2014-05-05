# Win32 Drag and Drop sample program for Dlang
- Win32 の Drag and Drop を実装してみました。
サンプル程度なのでご注意ください。(-_-)v 
- It is implementing a Drag and Drop of Win32 system.
Warning! Please note This is a sample program level. :-)

## Building Requirements
- MS-Windows Operating system.
- Compiler: [DMD] v2.065 or [GDC] 2.065.

[DMD]: http://dlang.org/download.html
[GDC]: http://gdcproject.org/downloads/

## Building

    $ Build.bat

or

    $ make


## Links
- D2 Programming Language Homepage: http://d-programming-language.org/
- D2 Programming Language Japanese: http://www.kmonos.net/alang/d/index.html
- DWinProgramming https://github.com/AndrejMitrovic/DWinProgramming

## check it
- 注意！以下の interface を書き換えています。
- I'm rewriting the 'interface' of the following

```dlang
win32/objidl.d
/++ Original
interface IEnumFORMATETC : IUnknown {
  HRESULT Next(ULONG, FORMATETC*, ULONG*);
  HRESULT Skip(ULONG);
  HRESULT Reset();
@ HRESULT Clone(IEnumFORMATETC**);
}
++/
interface IEnumFORMATETC: IUnknown {
  HRESULT Next(ULONG celt, FORMATETC* rgelt, ULONG* pceltFetched);
  HRESULT Skip(ULONG celt);
  HRESULT Reset();
  HRESULT Clone(IEnumFORMATETC* ppenum);
}
/++ Original
interface IDataObject : IUnknown {
  HRESULT GetData(FORMATETC*, STGMEDIUM*);
  HRESULT GetDataHere(FORMATETC*, STGMEDIUM*);
  HRESULT QueryGetData(FORMATETC*);
  HRESULT GetCanonicalFormatEtc(FORMATETC*, FORMATETC*);
  HRESULT SetData(FORMATETC*, STGMEDIUM*, BOOL);
@ HRESULT EnumFormatEtc(DWORD, IEnumFORMATETC**);
  HRESULT DAdvise(FORMATETC*, DWORD, IAdviseSink*, PDWORD);
  HRESULT DUnadvise(DWORD);
@ HRESULT EnumDAdvise(IEnumSTATDATA**);
}
++/
interface IDataObject : IUnknown {
  HRESULT GetData(FORMATETC*, STGMEDIUM*);
  HRESULT GetDataHere(FORMATETC*, STGMEDIUM*);
  HRESULT QueryGetData(FORMATETC*);
  HRESULT GetCanonicalFormatEtc(FORMATETC*, FORMATETC*);
  HRESULT SetData(FORMATETC*, STGMEDIUM*, BOOL);
  HRESULT EnumFormatEtc(DWORD, IEnumFORMATETC*);
  HRESULT DAdvise(FORMATETC*, DWORD, IAdviseSink*, PDWORD);
  HRESULT DUnadvise(DWORD);
  HRESULT EnumDAdvise(IEnumSTATDATA*);
}
```
//eof
