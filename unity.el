;;; unity.el --- Unity integration for Emacs -*- lexical-binding:t -*-
;;; Commentary:
;;; Code:

(defgroup unity nil
  "Unity game engine integration."
  :group 'external)

(defcustom unity-var-directory
  (expand-file-name (convert-standard-filename "var/unity/")
                    user-emacs-directory)
  "Directory for persistent data."
  :type 'string
  :group 'unity)

(defcustom unity-cc
  "gcc"
  "C compiler command to build code shim on Unix-like systems."
  :type 'string
  :group 'unity)

(defun unity--code-binary-file ()
  "Return the file name of the code shim."
  (concat unity-var-directory (if (eq system-type 'windows-nt)
                                  "code.exe"
                                "code")))

(defun unity--project-path-p (path)
  "Return t if PATH is in a Unity project."
  (string-match-p "/[Aa]ssets/" path))

(defun unity--rename-file-advice (file newname &optional ok-if-already-exists)
  "Advice function for `rename-file' for renaming Unity files.

FILE, NEWNAME, and OK-IF-ALREADY-EXISTS are documented by `rename-file'."
  (when (unity--project-path-p file)
    (let ((meta-file (concat file ".meta")))
      (when (file-exists-p meta-file)
        (rename-file meta-file (concat newname ".meta")
                     ok-if-already-exists)))))

(defun unity--build-code-shim ()
  "Build the code shim."
  (make-directory unity-var-directory t)
  (when (get-buffer "*unity-subprocess*")
    (kill-buffer "*unity-subprocess*"))
  (let ((subprocess-buffer (get-buffer-create "*unity-subprocess*"))
        (source-name
         (concat (file-name-directory (or load-file-name buffer-file-name))
                 (if (eq system-type 'windows-nt)
                     "code-windows.c"
                   "code-unix.c"))))
    (if (eq (call-process unity-cc nil subprocess-buffer nil
                          source-name "-o" (unity--code-binary-file))
            0)
        (progn
          (kill-buffer subprocess-buffer)
          (message "Unity code shim built successfully."))
      (progn
        (switch-to-buffer-other-window subprocess-buffer)
        (special-mode)))))

(defun unity-build-code-shim ()
  "Build the code shim if it's not already built."
  (unless (file-exists-p (unity--code-binary-file))
    (unity-build-code-shim)))

(defun unity-rebuild-code-shim ()
  "Force rebuild the code shim."
  (when (file-exists-p (unity--code-binary-file))
    (delete-file (unity--code-binary-file)))
  (unity--build-code-shim))

(defun unity-setup ()
  "Activate Unity.el integration."
  (interactive)
  (advice-add #'rename-file :after #'unity--rename-file-advice))

(provide 'unity)

;;; unity.el ends here
