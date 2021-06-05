# unity.el

This package provides some Emacs integration with the Unity game engine. Most
notably, it provides the ability to open source files from Unity in Emacs or
Emacsclient while still generating the solution and project files for use with
`lsp-mode`.

Additionally, this package can install hooks/advice for smoother interop with
certain Unity quirks. **Note that these (optional) integrations are experimental
and potentially destructive**; see the `unity-setup` section for more
information.

## Installation

Currently, this package is not on M?ELPA. In the meantime, please clone and
extend your load path. I recommend
[straight.el](https://github.com/raxod502/straight.el). For example:

```elisp
(straight-use-package
 '(unity :type git :host github :repo "elizagamedev/unity.el"
         :files ("*.el" "*.c")))
(add-hook 'after-init-hook #'unity-build-code-shim)
(add-hook 'after-init-hook #'unity-setup)
```

## Configuration

`unity.el` exposes two functions, `unity-build-code-shim` and `unity-setup`.

### `unity-build-code-shim`

Unity does not generate project or solution files unless the external text
editor is recognized as Visual Studio, Visual Studio Code, or MonoDevelop.
Unfortunately, this means that other editors which wish to leverage the power of
the OmniSharp language server are obtuse to use with Unity. `unity.el` provides
a workaround for this issue: it compiles a very simple binary named
`code`/`code.exe` which can be set as Unity's external editor to trick it into
generating the solution/project files as normal.

The shim simply invokes the remaining command line arguments as a command line.
For example, the following command runs `emacsclient Foo.cs`.

```sh
code emacsclient Foo.cs
```

`unity-build-code-shim` will compile the shim, placing the resulting
`code`/`code.exe` file in `[emacs-user-directory]/var/unity/`.

You can then change the "External Script Editor" setting to point to `code` and
adjust the "External Script Editor Args" arguments as such to run `emacsclient`
(or any program of your choosing, for that matter).

```sh
emacsclient -n +$(Line):$(Column) $(File)
```

### `unity-setup`

This function installs any hooks, advice, etc. necessary for smoother
Emacs/Unity interop. Currently this is limited to advising `rename-file` and
`delete-file` so that `.meta` files are automatically moved and deleted
alongside their associated files.

While it's unlikely that there are any disasterous bugs lurking in the advice
functions, given that these are destructive operations, *please be mindful* if
you are calling `unity-setup`. Always use revision control.
