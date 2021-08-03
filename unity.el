;;; unity.el --- Unity integration for Emacs -*- lexical-binding:t -*-

;; Version: 0.1.2
;; Author: Eliza Velasquez
;; Created: 30 May 2021
;; Keywords: unity
;; URL: https://github.com/elizagamedev/unity.el

;;; Commentary:

;; This package provides some Emacs integration with the Unity game engine.
;; Most notably, it provides the ability to open source files from Unity in
;; Emacs or Emacsclient while still generating the solution and project files
;; for use with `lsp-mode'.
;;
;; Additionally, this package can install hooks/advice for smoother interop with
;; certain Unity quirks.
;;
;; See README.md for more information.

;;; Code:

(defgroup unity nil
  "Unity game engine integration."
  :group 'external)

(defcustom unity-var-directory
  (expand-file-name (convert-standard-filename "var/unity/")
                    user-emacs-directory)
  "Directory for persistent data."
  :type 'directory
  :group 'unity)

(defcustom unity-code-shim-source-directory
  (file-name-directory (or (locate-library "unity")
                           load-file-name
                           buffer-file-name))
  "Directory containing the code shim source."
  :type 'directory
  :group 'unity)

(defcustom unity-cc
  "gcc"
  "C compiler command to build code shim on Unix-like systems."
  :type 'string
  :group 'unity)

(defcustom unity-vcvarsall-file
  "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Auxiliary/Build/vcvarsall.bat"
  "Location of vcvarsall.bat on Windows.

See https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line."
  :type 'file
  :group 'unity)

(defcustom unity-vcvarsall-arch
  "x64"
  "Target architecture of vcvarsall.bat.

See https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line."
  :type 'string
  :group 'unity)

(defun unity--project-path-p (path)
  "Return t if PATH is in a Unity project."
  (let ((case-fold-search t))
    (if (string-match-p "/assets/" path) t)))

(defun unity--rename-file-advice (file newname &optional ok-if-already-exists)
  "Advice function for `rename-file' for renaming Unity files.

FILE, NEWNAME, and OK-IF-ALREADY-EXISTS are documented by `rename-file'."
  (when (and (unity--project-path-p file)
             (unity--project-path-p newname))
    (let ((meta-file (concat file ".meta")))
      (when (file-exists-p meta-file)
        (rename-file meta-file (concat newname ".meta")
                     ok-if-already-exists)))))

(defun unity--delete-file-advice (file &optional trash)
  "Advice function for `delete-file' for deleting Unity files.

FILE and TRASH are documented by `rename-file'."
  (when (unity--project-path-p file)
    (let ((meta-file (concat file ".meta")))
      (when (file-exists-p meta-file)
        (delete-file meta-file trash)))))

(defun unity--code-binary-file ()
  "Return the file name of the code shim binary."
  (concat unity-var-directory (if (eq system-type 'windows-nt)
                                  "code.exe"
                                (if (eq system-type 'darwin)
                                    "code.app"
                                "code"))))

(defun unity--build-code-shim-unix (subprocess-buffer)
  "Build the code shim on Unix and output to SUBPROCESS-BUFFER."
  (call-process unity-cc nil subprocess-buffer nil
                "-O2" (expand-file-name "code-unix.c"
                                        unity-code-shim-source-directory)
                "-o" (unity--code-binary-file)))

(defun unity--build-code-shim-windows (subprocess-buffer)
  "Build the code shim on Windows and output to SUBPROCESS-BUFFER."
  (let ((temp-script (make-temp-file "emacs-unity" nil ".bat"))
        (temp-object (make-temp-file "emacs-unity" nil ".obj")))
    (unwind-protect
        (progn
          (with-temp-file temp-script
            (setq-local buffer-file-coding-system 'utf-8)
            (insert
             (format
              "chcp 65001
call \"%s\" %s || exit /b 1
@echo on
cl /nologo /O2 \"%s\" /Fo\"%s\" /Fe\"%s\" user32.lib shlwapi.lib || exit /b 1"
              ;; call vcvarsall.bat.
              (convert-standard-filename
               (expand-file-name unity-vcvarsall-file))
              unity-vcvarsall-arch
              ;; cl.
              (convert-standard-filename
               (expand-file-name "code-windows.c"
                                 unity-code-shim-source-directory))
              (convert-standard-filename
               (expand-file-name temp-object))
              (convert-standard-filename
               (expand-file-name (unity--code-binary-file))))))
          (call-process "cmd" nil subprocess-buffer nil
                        "/c" temp-script))
      (progn
        (delete-file temp-script)
        (delete-file temp-object)))))

;;;###autoload
(defun unity-build-code-shim (&optional force-rebuild)
  "Build the code shim.

This function is a no-op if the code shim is already built unless
FORCE-REBUILD is t. This argument is always t when invoked
interactively."
  (interactive '(t))
  (when (or (not (file-exists-p (unity--code-binary-file)))
            force-rebuild)
    (make-directory unity-var-directory t)
    (when (get-buffer "*unity-subprocess*")
      (kill-buffer "*unity-subprocess*"))
    (let ((subprocess-buffer (get-buffer-create "*unity-subprocess*")))
      (if (eq (if (eq system-type 'windows-nt)
                  (unity--build-code-shim-windows subprocess-buffer)
                (unity--build-code-shim-unix subprocess-buffer))
              0)
          (progn
            (kill-buffer subprocess-buffer)
            (message "Unity code shim built successfully."))
        (progn
          (switch-to-buffer-other-window subprocess-buffer)
          (special-mode))))))

;;;###autoload
(defun unity-setup ()
  "Activate Unity.el integration."
  (interactive)
  (advice-add #'rename-file :after #'unity--rename-file-advice)
  (advice-add #'delete-file :after #'unity--delete-file-advice))

(provide 'unity)

;;; unity.el ends here
