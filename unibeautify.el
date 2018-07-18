;;; unibeautify.el --- Auto-format source code using Unibeautify -*- lexical-binding: t -*-
;;
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/Unibeautify/emacs
;; Version: 0.1.0
;; Package-Requires: ((cl-lib "0.5"))
;; Keywords: languages util
;; License: MIT
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Lets you auto-format source code in numerous languages using
;; Unibeautify.
;;
;;; Code:

(defun unibeautify-language-from-buffer ()
  (case major-mode
    (c++-mode "C++")
    (c-mode "C")
    (css-mode "CSS")
    (gfm-mode "Markdown")
    (go-mode "Go")
    (graphql-mode "GraphQL")
    (java-mode "Java")
    (js-mode "JavaScript")
    (js2-mode "JavaScript")
    (js3-mode "JavaScript")
    (json-mode "JSON")
    (jsx-mode "JSX")
    (less-css-mode "Less")
    (markdown-mode "Markdown")
    (objc-mode "Objective-C")
    (scss-mode "SCSS")
    (typescript-mode "TypeScript")
    (typescript-tsx-mode "TypeScript")
    (vue "Vue")
    (t (error "Don't know how to format %S code" major-mode))))

(defun unibeautify ()
  "Auto-format the source code in the current buffer using Unibeautify."
  (interactive)
  (unless (executable-find "unibeautify")
    (error "Please install the 'unibeautify' executable."))
  (save-excursion
    (save-restriction
      (widen)
      (let ((language (unibeautify-language-from-buffer))
            (inbuf (current-buffer))
            (input (buffer-substring-no-properties (point-min) (point-max)))
            errput errorp first-diff no-chg output)
        (with-temp-buffer
          (let* ((errfile (make-temp-file "unibeautify-emacs-"))
                 (status (apply #'call-process-region input nil
                                "unibeautify" nil (list t errfile)
                                nil (list "--language" language))))
            (setq errput (with-temp-buffer
                           (insert-file-contents errfile)
                           (delete-file errfile)
                           (buffer-substring (point-min) (point-max)))
                  errorp (not (equal 0 status))
                  first-diff (abs (compare-buffer-substrings inbuf nil nil
                                                             nil nil nil))
                  no-chg (or errorp (= 0 first-diff))
                  output (unless no-chg
                           (buffer-substring (point-min) (point-max))))))
        (cond (errorp
               (message "Syntax error"))
              (no-chg
               (message "Already formatted"))
              (t
               (message "Reformatted!")
               (erase-buffer)
               (insert output)
               (goto-char first-diff)))
        (with-current-buffer (get-buffer-create "*unibeautify-errors*")
          (erase-buffer)
          (unless (= 0 (length errput))
            (insert errput)
            (display-buffer (current-buffer))))))))

(provide 'unibeautify)

;;; unibeautify.el ends here
