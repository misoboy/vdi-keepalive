#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

configPath := A_ScriptDir "\config.ini"

intervalSec   := Integer(IniRead(configPath, "General", "IntervalSec", "300"))
pauseMs       := Integer(IniRead(configPath, "General", "WindowSwitchPauseMs", "80"))
skipMinimized := Integer(IniRead(configPath, "General", "SkipIfMinimized", "1"))

keywords := []
loop {
    val := IniRead(configPath, "Targets", "Keyword" A_Index, "")
    if (val = "")
        break
    keywords.Push(val)
}

if (keywords.Length = 0) {
    MsgBox("config.ini 의 [Targets] 섹션에 Keyword1= 값을 설정하세요.`n`n예: Keyword1=Citrix", "VDI Keep-Alive", "Iconx")
    ExitApp()
}

paused := false
SetTitleMatchMode(2)

A_TrayMenu.Delete()
A_TrayMenu.Add("VDI Keep-Alive", DoNothing)
A_TrayMenu.Disable("VDI Keep-Alive")
A_TrayMenu.Add()
A_TrayMenu.Add("일시정지 / 재개", TogglePause)
A_TrayMenu.Add("지금 한 번 실행", RunNow)
A_TrayMenu.Add("설정 파일 열기", OpenConfig)
A_TrayMenu.Add()
A_TrayMenu.Add("종료", ExitNow)
A_TrayMenu.Default := "지금 한 번 실행"
UpdateTip()

SetTimer(Tick, intervalSec * 1000)

DoNothing(*) {
}

TogglePause(*) {
    global paused
    paused := !paused
    UpdateTip()
}

RunNow(*) {
    Tick()
}

OpenConfig(*) {
    global configPath
    Run('notepad.exe "' configPath '"')
}

ExitNow(*) {
    ExitApp()
}

UpdateTip() {
    global paused, intervalSec, keywords
    state := paused ? "일시정지" : "실행 중"
    A_IconTip := Format("VDI Keep-Alive ({1})`n주기: {2}초`n키워드: {3}", state, intervalSec, JoinKeywords())
}

JoinKeywords() {
    global keywords
    s := ""
    for kw in keywords
        s .= (s = "" ? "" : ", ") kw
    return s
}

Tick() {
    global paused, keywords, skipMinimized, pauseMs

    if paused
        return

    savedActive := WinExist("A")
    MouseGetPos(&mx, &my)

    seen := Map()

    for kw in keywords {
        try {
            windows := WinGetList(kw)
        } catch {
            continue
        }
        for hwnd in windows {
            if seen.Has(hwnd)
                continue
            seen[hwnd] := true
            try {
                if (skipMinimized && WinGetMinMax("ahk_id " hwnd) = -1)
                    continue
                WinActivate("ahk_id " hwnd)
                WinWaitActive("ahk_id " hwnd, , 1)
                MouseMove(1, 0, 0, "R")
                MouseMove(-1, 0, 0, "R")
                Send("{Shift}")
                Sleep(pauseMs)
            }
        }
    }

    if savedActive {
        try WinActivate("ahk_id " savedActive)
    }
    MouseMove(mx, my, 0)
}
