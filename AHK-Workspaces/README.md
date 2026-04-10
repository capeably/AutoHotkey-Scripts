# AHK-Workspaces

A window management tool for Windows built with AutoHotkey v1. Open a group of windows AND position them exactly how you want with a single hotkey. Press the same hotkey again to minimize or close them. Don't like hotkeys? Load these workspaces via the workspace launcher: set a hotkey for the launcher (e.g. Windows + Spacebar), type the name of the workspace, and press enter to launch it!

Workspaces was originally created by the incredible, the illustrious maestrith, and updated to this latest version (with workspace launcher and redesigned 3-pane GUI) by capeably with the help of a friend named Claude.

## What It Does

Workspaces lets you save groups of windows — their positions, sizes, and launch commands — into named workspaces. Activate a workspace by hotkey or by searching for it in the **Workspace Launcher**, a quick-search popup you can summon from anywhere. Windows that aren't open get launched automatically (if Auto Open is enabled), then everything snaps into the saved positions. Press the same hotkey again to minimize or close them. It also supports multiple monitor configurations, saving separate positions per monitor count so your layouts adapt automatically.

## Requirements

- [AutoHotkey v1.1+](https://www.autohotkey.com/) (Unicode build)

## Getting Started

1. Run `Workspaces.ahk`.
2. Click **Create Workspace** to make your first workspace.
3. Click **Add Windows** to capture open windows into the workspace.
4. Arrange your windows how you like, then click **Update Positions** to save their layout.
5. Press Enter on the workspace (left pane) or double-click the Hotkey column to assign a keyboard shortcut.

Now press that hotkey from anywhere to restore your workspace.

## Interface

The GUI has three panes:

**Left Pane — Workspace List:** All your workspaces with their assigned hotkeys. A search bar at the top filters by name or hotkey.

**Middle Pane — Window List:** The windows belonging to the selected workspace. Click a window to view its settings.

**Right Pane — Window Settings:** Configuration for the selected window, including match mode, class, exe, run command, toggle behaviors, and saved positions per monitor count.

## Keyboard Shortcuts

These work when the Workspaces GUI is focused. The action depends on which pane has focus.

| Key | Left Pane (Workspaces) | Middle Pane (Windows) | Right Pane (Settings) |
|---|---|---|---|
| **Enter** | Edit hotkey | Edit window title | Toggle/edit setting |
| **Delete** | Remove workspace | Remove window | Clear Run value |
| **Tab** | Focus middle pane | Focus right pane | — |
| **Shift+Tab** | — | Focus left pane | Focus middle pane |
| **Double-click** | Rename (col 1) / Edit hotkey (col 2) | Edit window title | Edit Run or Position value |
| **Right-click** | — | Activate & position window | Select folder for Run |

**Shift+Escape** exits the application.

## Window Settings

Each window in a workspace has the following settings, editable via Enter or double-click:

| Setting | Description |
|---|---|
| **Window Match Mode** | How the window title is matched: `contains`, `exact`, `startswith`, `endswith`, or `regex`. Cycle through options with Enter. |
| **Class** | The window class for more precise matching. |
| **Exe** | The process name (e.g. `chrome.exe`). |
| **Run** | The file path or command used to launch the window if it isn't already open. |
| **Auto Close** | When the workspace is dismissed, close this window instead of minimizing it. Toggle with Enter. |
| **Auto Open** | Automatically launch this window when the workspace is activated, if it isn't already running. Toggle with Enter. |
| **Maximize** | Maximize the window instead of restoring to a specific position. Toggle with Enter. |
| **Monitor Count / Position** | Saved window positions, stored per monitor count. Positions update automatically when you click Update Positions. |

## Workspace Launcher

The Workspace Launcher is a quick-search popup — similar to Launchy, Alfred, or the Windows Run dialog — that lets you activate any workspace without remembering its hotkey. Assign a global hotkey to it (the default is `Ctrl+Alt+Space`) and it's available from any application.

When the launcher opens, just start typing. The list filters in real time to match workspace names. Use the **Up/Down** arrow keys to select a result, then press **Enter** to activate it. Press **Escape** to dismiss. The launcher automatically hides when it loses focus.

You can change the launcher's hotkey from the **Settings > Edit Hotkeys** menu.

## Settings Menu

The menu bar has a **Settings** menu with three configurable actions, each assignable to a global hotkey via **Edit Hotkeys**:

- **Hide/Show GUI** — Toggle the Workspaces window.
- **Toggle Current Workspace** — Cycle through workspaces, restoring each one in turn.
- **Workspace Launcher** — Open the quick-search launcher described above. Default hotkey: `Ctrl+Alt+Space`.

## How Hotkeys Work

Workspace hotkeys are global — they work from any application. Pressing a workspace hotkey when its windows are already in position will minimize (or close, if Auto Close is enabled) all windows in that workspace. Pressing it again restores them. This toggle behavior lets a single hotkey both activate and dismiss a workspace.

## Data Storage

All workspace data is saved to `settings.xml` in the script directory. The file is written on exit and uses UTF-16 encoding. Positions are stored per monitor count, so if you switch between a single-monitor and dual-monitor setup, each layout is remembered separately.
