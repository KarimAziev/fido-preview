;;; fido-preview.el --- File preview for fido -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Karim Aziiev <karim.aziiev@gmail.com>

;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; URL: https://github.com/KarimAziev/fido-preview
;; Version: 0.1.0
;; Keywords: files
;; Package-Requires: ((emacs "28.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; File preview for fido

;;; Code:

(defun fido-preview--file (file)
  "Preview FILE or it's buffer without visiting."
  (let ((buffer (get-buffer-create "*fido-preview*")))
    (with-minibuffer-selected-window
      (with-current-buffer (get-buffer-create buffer)
        (erase-buffer)
        (if-let ((buff (get-file-buffer file)))
            (insert (with-current-buffer buff
                      (buffer-string)))
          (insert-file-contents file)
          (let ((buffer-file-name file))
            (delay-mode-hooks (set-auto-mode)
                              (font-lock-ensure))))
        (setq header-line-format
              (abbreviate-file-name file))
        (unless (get-buffer-window (current-buffer))
          (pop-to-buffer-same-window (current-buffer)))))))

(defun fido-preview-get-file ()
  "Return FILE from `minibuffer-contents'."
  (let ((content (minibuffer-contents)))
    (when (and
           content
           (string-empty-p content)
           (car completion-all-sorted-completions))
      (setq content (car completion-all-sorted-completions)))
    (when (and (file-exists-p content)
               (file-readable-p content)
               (file-name-absolute-p content))
      (if (file-directory-p content)
          (let* ((dir (file-name-directory content))
                 (current (car completion-all-sorted-completions))
                 (file (and dir current
                            (expand-file-name (directory-file-name current)
                                              (substitute-env-vars dir)))))
            (when (and file
                       (file-name-absolute-p file)
                       (file-exists-p file)
                       (file-readable-p file))
              file))
        content))))

;;;###autoload
(defun fido-preview-find-file-other-window ()
  "Find file in other window and abort the current minibuffer.
File is detected from `minibuffer-contents'."
  (interactive)
  (when-let ((file (fido-preview-get-file)))
    (run-at-time 0.2 nil #'find-file-other-window file)
    (abort-minibuffers)))

;;;###autoload
(defun fido-preview-file ()
  "Preview `minibuffer-contents' if it is a file.
Files with size greater than `large-file-warning-threshold' is ignored."
  (interactive)
  (when-let ((file (fido-preview-get-file)))
    (when (and (not (file-directory-p file))
               (not (and large-file-warning-threshold
                         (> (file-attribute-size
                             (file-attributes file))
                            large-file-warning-threshold))))
      (fido-preview--file file))))

(provide 'fido-preview)
;;; fido-preview.el ends here