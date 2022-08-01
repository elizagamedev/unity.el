# unity.el

This package provides some Emacs integration with the Unity game engine. It
installs hooks/advice for smoother interop with certain Unity quirks. It's
intended to be used along-side
[rider2emacs](https://github.com/elizagamedev/rider2emacs) so that Unity will
open source files in Emacs and generate the appropriate solution/project files
necessary for LSP integration.

**Note that these integrations are potentially destructive**; see the
`unity-mode` section for more information.

## Installation

Currently, this package is not on M?ELPA. In the meantime, please clone and
extend your load path. I recommend
[straight.el](https://github.com/raxod502/straight.el). For example:

```elisp
(straight-use-package
 '(unity :type git :host github :repo "elizagamedev/unity.el"))
(add-hook 'after-init-hook #'unity-mode)
```

## Usage

### `unity-mode`

When active, this mode installs hooks, advice, etc. necessary for smoother
Emacs/Unity interop. Currently this is limited to advising `rename-file` and
`delete-file` so that `.meta` files are automatically moved and deleted
alongside their associated files.

While it's unlikely that there are any disasterous bugs lurking in the advice
functions, given that these are destructive operations, *please be mindful* if
you are enabling `unity-mode`. Always use revision control.

### `rider2emacs`

unity.el is intended to be used alongside
[rider2emacs](https://github.com/elizagamedev/rider2emacs), which provides Unity
with the ability to open files in Emacs and generate project files for use with
OmniSharp LSP. See its documentation for details.

### `unity-build-code-shim` (Obsolete)

*The functionality described in this section has been superseded with
[rider2emacs](https://github.com/elizagamedev/rider2emacs), but is left here in
its original text for posterity.*

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

On some platforms like macOS, Unity may not be inherit your base PATH when
running the shim. If the editor is not launching as expected you should use an
absolute path. An example of "External Script Editor Args" might look like:

```sh
/usr/local/bin/emacsclient -n +$(Line):$(Column) $(File)
```
