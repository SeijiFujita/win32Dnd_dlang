/++
 Win32 Drag and Drop demo 


++/

module drop_source;

import std.string;

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import utils;
import debugLog;

class DropSource : ComObject, IDropSource
{
    this() { outLog("CDropSource:this"); }
    ~this() { outLog("CDropSource:~this"); }

    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        // outLog("CDropSource:QueryInterface");
        if (*riid == IID_IDropSource)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }

        return super.QueryInterface(riid, ppv);
    }

//
// キーやマウスボタンの状態をみて、ドラッグを続けるかやめるかを決める
// Called by OLE whenever Escape/Control/Shift/Mouse buttons have changed.
    extern (Windows)
    HRESULT QueryContinueDrag(BOOL fEscapePressed, DWORD grfKeyState)
    {
        outLog("CDropSource:QueryContinueDrag");
        // if the <Escape> key has been pressed since the last call, cancel the drop
        if (fEscapePressed == TRUE)
            return DRAGDROP_S_CANCEL;

        // if the <LeftMouse> button has been released, then do the drop!
        if ((grfKeyState & MK_LBUTTON) == 0)
            return DRAGDROP_S_DROP;

        // continue with the drag-drop
        return S_OK;
    }

// マウスカーソルの形状を変えたり、特殊効果を出したりするための関数
// DRAGDROP_S_USEDEFAULTCURSORSを返しておけばあとはWindwosが勝手にやってくれます
// Return either S_OK or DRAGDROP_S_USEDEFAULTCURSORS to instruct OLE to use the
//  default mouse cursor images
    extern (Windows)
    HRESULT GiveFeedback(DWORD dwEffect)
    {
        outLog("CDropSource:GiveFeedback");
        return DRAGDROP_S_USEDEFAULTCURSORS;
    }
}
