/++
 Win32 Drag and Drop demo 
 winMain.d

++/


import core.runtime;
import std.exception;
import std.string;
import std.utf;

version(Unicode) {
    const(TCHAR)* _T( wstring str ) { return (str ~ "\0").ptr; }

     string TtoC( immutable(TCHAR)* tc ) { return TtoW(tc).toUTF8(); }
    wstring TtoW( immutable(TCHAR)* tc ) { return tc[0..lstrlen(cast(TCHAR*)tc)]; }
}
else {
    import std.windows.charset;
    const(TCHAR)* _T( string str ) { return str.toMBSz(); }

     string TtoC( immutable(TCHAR)* tc ) { return fromMBSz(tc); }
    wstring TtoW( immutable(TCHAR)* tc ) { return fromMBSz(tc).toUTF16(); }
}

pragma(lib, "ole32.lib");
pragma(lib, "comctl32.lib");
pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;

import win32.objidl;
import win32.shellapi;
import win32.ole2;

// local
import enum_format;
import data_object;
import drop_target;
import drop_source;
import utils;
import debugLog;

enum Window_StrtPotition = CW_USEDEFAULT;
enum Window_ClientWidth  = 600;
enum Window_ClientHeight = 200;

string appName = "DnDsample";
string description = "DnDsampleClass";

HINSTANCE g_hInstance;
HWND hwndMain;
WNDPROC functionEditWndProc;


extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;
    try
    {
        Runtime.initialize();
        setDebugLog();
        g_hInstance = hInstance;
        result = xWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        outLog("#---End");
        Runtime.terminate();
    }
    catch (Throwable o)
    {
        MessageBox(null, _T(o.toString()), _T("Error"), MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }
    return result;
}

int xWinMain(HINSTANCE xhInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    WNDCLASSEX wndclassEx;

    enforce(OleInitialize(null) == S_OK);
    scope (exit)
        OleUninitialize();

    // http://eternalwindows.jp/winbase/window/window01.html
    with (wndclassEx) {
        cbSize        = wndclassEx.sizeof;
        style         = CS_HREDRAW | CS_VREDRAW;
        lpfnWndProc   = &WndProc;
        cbClsExtra    = 0;
        cbWndExtra    = 0;
        hInstance     = xhInstance;
        hIcon         = LoadIcon(NULL, IDI_APPLICATION);
        hCursor       = LoadCursor(NULL, IDC_ARROW);
        hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
        lpszMenuName  = null;
        lpszClassName = _T(appName);
        hIconSm       = LoadIcon(NULL, IDI_APPLICATION);
    }
    
    if (RegisterClassEx(&wndclassEx) == 0)
    {
        MessageBox(NULL, _T("RegistarClassEx Error!"), _T(appName), MB_ICONERROR);
        return 0;
    }
    hwndMain = CreateWindowEx(
        WS_EX_OVERLAPPEDWINDOW,     //  WS_EX_COMPOSITED
        _T(appName),                    // window class name
        _T(description),                // window caption
        WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,            // window style
        CW_USEDEFAULT,                  // initial x position
        CW_USEDEFAULT,                  // initial y position
        Window_ClientWidth,             // initial x size
        Window_ClientHeight,            // initial y size
        null,                           // parent window handle
        null,                           // window menu handle
        xhInstance,                     // program instance handle
        null);                          // creation parameters
    
    ShowWindow(hwndMain, iCmdShow);
    UpdateWindow(hwndMain);
    
    MSG  msg;
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static DropTarget dt;
    static bool flag_OneShot_mouse_down;
    
    switch (message)
    {
        case WM_DESTROY:
        {
            outLog("WM_DESTROY");
			dt.RevokeDropTarget();
            delete dt;
            PostQuitMessage(0);
            showMMgr();
            cleanMMgr();
            outLog("WM_DESTROY:End");
            return 0;
        }
        
        case WM_CREATE:
        {
            outLog("WM_CREATE");
            dt = new DropTarget(hwnd);
            dt.RegisterDropTarget();
            dropSetText("It is possible to drag and drop in this window.");
            InvalidateRect(hwnd, NULL, TRUE);
            SetFocus(hwnd);
            outLog("WM_CREATE:1");
            showMMgr();
            outLog("WM_CREATE:2");
            return 0;
        }
        
        case WM_PAINT:
        {
            outLog("WM_PAINT");
            return OnPaint(hwnd, wParam);
        }
        
        case WM_LBUTTONDOWN:
        {
        	outLog("WM_LBUTTONDOWN");
            if (flag_OneShot_mouse_down == false) {
                flag_OneShot_mouse_down = true;
				
                OnLButtonDown(wParam, lParam);
				
                flag_OneShot_mouse_down = false;
            }
            return 0;
        }
        
        default:
    }
    
    return DefWindowProc(hwnd, message, wParam, lParam);
}


LRESULT OnPaint(HWND hwnd, WPARAM wParam)
{
    PAINTSTRUCT ps;
    HDC  hDC;
    string text = dropGetText();
    outLog("text:", text);
    
    RECT rt;
    GetClientRect(hwnd, &rt);
    rt.top += 5; rt.bottom -= 5; rt.right -= 5; rt.left += 5;
    
    hDC = BeginPaint(hwnd, &ps);
    // TextOut(hDC, 5, 25, text.toStringz, text.length);
    DrawText(hDC, _T(text), -1, &rt, DT_WORDBREAK);
    EndPaint (hwnd, &ps);
    return 0;
}

LRESULT OnLButtonDown(WPARAM wParam, LPARAM lParam)
{
    outLog("====DoDragDrop:1");
    showMMgr();

    DWORD dwEffect;
    DWORD dwResult;
    //
    DataObject pDataObject = new DataObject;
    DropSource pDropSource = new DropSource;
    
    //    string[] filesList = getFiles("./");
	//    pDataObject.dropFile(filesList);
    pDataObject.dropText(dropGetText());
    
    outLog("====DoDragDrop:2");
    // Star the drag & drop operation
    dwResult = DoDragDrop(pDataObject, pDropSource, 
                          DROPEFFECT.DROPEFFECT_COPY | DROPEFFECT.DROPEFFECT_MOVE,
                          &dwEffect);
      
    outLog("====DoDragDrop:3");
    // success!
    if (dwResult == DRAGDROP_S_DROP) {
        if (dwEffect & DROPEFFECT.DROPEFFECT_MOVE) {
            outLog("====DoDragDrop:4");
            MessageBox(null, "Moving", "Info", MB_OK);
        }
    }
    else if (dwResult == DRAGDROP_S_CANCEL) {
        outLog("====DoDragDrop:5");
    }
     
	delete pDataObject;
	delete pDropSource;
    showMMgr();
    outLog("====DoDragDrop:6");
    return 0;
}
// eof
