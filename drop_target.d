/++
 Win32 Drag and Drop demo 
 CF_TEXT drop_target

++/

module drop_target;

import std.string;

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;
import win32.shellapi;

import utils;
import debugLog;

private string _text;

string dropGetText()
{
    return _text.length ? _text : "";
}

void dropSetText(string s)
{
    _text = s;
}

void dropSetText(char *s)
{
    _text = cPtrToString(s);
}


class DropTarget : ComObject, IDropTarget
{
private:
    HWND m_hWnd;
    bool m_fAllowDrop;
    IDataObject _DataObject;

public:

    this(HWND hwnd)
    {
		outLog("DropTarget:this");
        m_hWnd       = hwnd;
        m_fAllowDrop = false;
    }
	void RegisterDropTarget()
	{
		outLog("DropTarget:RegisterDropTarget");
		HRESULT result;
		if ((result = RegisterDragDrop(m_hWnd, this)) != S_OK) {
			if (result == DRAGDROP_E_INVALIDHWND)
				outLog("DRAGDROP_E_INVALIDHWND");
			else if (result == DRAGDROP_E_ALREADYREGISTERED)
				outLog("DRAGDROP_E_ALREADYREGISTERED");
			else if (result == E_OUTOFMEMORY) 
				outLog("E_OUTOFMEMORY");
			else
				outLog("Undefined");
		}
	}
	void RevokeDropTarget()
	{
		outLog("DropTarget:RevokeDropTarget");
		HRESULT result;
        if (RevokeDragDrop(m_hWnd) != S_OK) {
            if (result == DRAGDROP_E_NOTREGISTERED)
                outLog("DRAGDROP_E_NOTREGISTERED");
            else if (result == DRAGDROP_E_INVALIDHWND)
                outLog("DRAGDROP_E_INVALIDHWND");
            else if (result == E_OUTOFMEMORY)
                outLog("E_OUTOFMEMORY");
			else
				outLog("Undefined");
            
        }
	}

// IDropTarget interfaces
    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        if (*riid == IID_IDropTarget)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        return super.QueryInterface(riid, ppv);
    }

// ドロップされると呼ばれる
    extern (Windows)
    HRESULT DragEnter(IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
    {
		outLog("DropTarget:DragEnter");
        _DataObject = pDataObject;
        return DragOver(grfKeyState, pt, pdwEffect);
    }

//ドロップ状態でマウスのポインタが移動すると呼ばれる POINTL に注意
    extern (Windows)
    HRESULT DragOver(DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
    {
		outLog("DropTarget:DragOver");
        if (QueryFormat(CF_TEXT)) {
			// *pdwEffect = DropEffect(grfKeyState, pt, DROPEFFECT.DROPEFFECT_COPY);
            *pdwEffect = DROPEFFECT.DROPEFFECT_COPY;
        } else {
            *pdwEffect = DROPEFFECT.DROPEFFECT_NONE;
        }
        return S_OK;
    }

//ドロップ状態でマウスのポインタが Window の外に出ると呼ばれる
    extern (Windows)
    HRESULT DragLeave()
    {
		outLog("DropTarget:DragLeave");
        return S_OK;
    }

//ドロップされると呼ばれる
    extern (Windows)
    HRESULT Drop(IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
    {
		outLog("DropTarget:Drop");
        FORMATETC text_fmt =  { CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL };
        STGMEDIUM	medium;
        
        if (pDataObject.GetData(&text_fmt, &medium) == S_OK) {
            char *buf = cast(char*)GlobalLock(medium.hGlobal);
            dropSetText(buf);
            GlobalUnlock(medium.hGlobal);
            ReleaseStgMedium(&medium);
            *pdwEffect = DROPEFFECT.DROPEFFECT_COPY;
        }
        else {
            *pdwEffect = DROPEFFECT.DROPEFFECT_NONE;
        }
        InvalidateRect(m_hWnd, NULL, TRUE);
        return S_OK;
    }

private:

    private bool QueryFormat(CLIPFORMAT cfFormat)
    {
        FORMATETC fmt;
        
        fmt.cfFormat = cfFormat;
        fmt.ptd = null;
        fmt.dwAspect = DVASPECT.DVASPECT_CONTENT;
        fmt.lindex = -1;
        fmt.tymed = TYMED.TYMED_HGLOBAL;
        return _DataObject.QueryGetData(&fmt) == S_OK ? true : false;
    }
    
    private DWORD DropEffect(DWORD grfKeyState, POINTL pt, DWORD dwAllowed)
    {
        DWORD dwEffect = 0;

        if (grfKeyState & MK_CONTROL)
        {
            dwEffect = dwAllowed & DROPEFFECT.DROPEFFECT_COPY;
        }
        else if (grfKeyState & MK_SHIFT)
        {
            dwEffect = dwAllowed & DROPEFFECT.DROPEFFECT_MOVE;
        }

        if (dwEffect == 0)
        {
            if (dwAllowed & DROPEFFECT.DROPEFFECT_COPY)
                dwEffect = DROPEFFECT.DROPEFFECT_COPY;
            
            if (dwAllowed & DROPEFFECT.DROPEFFECT_MOVE)
                dwEffect = DROPEFFECT.DROPEFFECT_MOVE;
        }
        return dwEffect;
    }

}
//eof
