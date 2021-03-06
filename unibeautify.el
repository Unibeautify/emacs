;;; unibeautify.el --- Auto-format source code using Unibeautify -*- lexical-binding: t -*-
;;
;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/Unibeautify/emacs
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
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
;; Unibeautify is a project to create a universal interface to as many
;; existing source code beautifiers as possible. It is installed from
;; the npm package manager. Individual beautifiers are supplied by
;; their own npm packages. Installation instructions:
;; https://unibeautify.com/docs/editor-emacs
;;
;; Unibeautify, and this Emacs package, are still work in
;; progress. They are already usable for basic tasks but design and
;; implementation work is still ongoing for the advanced
;; features. Development happens at https://github.com/Unibeautify
;;
;;; Code:

(defun unibeautify-preserve-line-number (thunk)
  "Internal function to preserve line and column number across edits."
  (let ((old-line-number (line-number-at-pos nil t))
        (old-column (current-column)))
    (funcall thunk)
    (goto-char (point-min))
    (forward-line (1- old-line-number))
    (let ((line-length (- (point-at-eol) (point-at-bol))))
      (goto-char (+ (point) (min old-column line-length))))))

(defun unibeautify-language-from-buffer ()
  "Internal function to get GitHub Linguist langauge name for current buffer."
  (or (case major-mode
        (c++-mode "C++")
        (c-mode "C")
        (css-mode "CSS")
        (elm-mode "Elm")
        (enh-ruby-mode "Ruby")
        (gfm-mode "Markdown")
        (go-mode "Go")
        (graphql-mode "GraphQL")
        (html-helper-mode "HTML")
        (html-mode "HTML")
        (java-mode "Java")
        (js-mode "JavaScript")
        (js2-jsx-mode "JSX")
        (js2-mode "JavaScript")
        (js3-mode "JavaScript")
        (json-mode "JSON")
        (jsx-mode "JSX")
        (less-css-mode "Less")
        (markdown-mode "Markdown")
        (mhtml-mode "HTML")
        (nxhtml-mode "HTML") ; TODO: Should this be HTML or XML?
        (nxml-mode "XML")
        (objc-mode "Objective-C")
        (php-mode "PHP")
        (protobuf-mode "Protocol Buffer")
        (python-mode "Python")
        (rjsx-mode "JSX")
        (ruby-mode "Ruby")
        (scss-mode "SCSS")
        (sql-mode "SQL")
        (typescript-mode "TypeScript")
        (typescript-tsx-mode "TypeScript")
        (vue-mode "Vue")
        (web-mode
         (when (equal "none" (symbol-value 'web-mode-engine))
           (let ((ct (symbol-value 'web-mode-content-type)))
             (cond ((equal ct "css") "CSS")
                   ((equal ct "html") "HTML")
                   ((equal ct "javascript") "JavaScript")
                   ((equal ct "json") "JSON")
                   ((equal ct "jsx") "JSX")
                   ((equal ct "xml") "XML")))))
        (xml-mode "XML"))
      (error "Don't know how to format %S code" major-mode)))

;;;###autoload
(defun unibeautify ()
  "Auto-format the source code in the current buffer using Unibeautify."
  (interactive)
  (unless (executable-find "unibeautify")
    (error "Please install the 'unibeautify' executable"))
  (save-excursion
    (save-restriction
      (widen)
      (let ((language (unibeautify-language-from-buffer))
            (inbuf (current-buffer))
            (input (buffer-string))
            errput errorp no-chg output)
        (with-temp-buffer
          (let* ((errfile (make-temp-file "unibeautify-emacs-"))
                 (status (apply #'call-process-region input nil
                                "unibeautify" nil (list t errfile)
                                nil (append (list "--language" language)
                                            (when (buffer-file-name inbuf)
                                              (list "--file-path"
                                                    (buffer-file-name inbuf)))))))
            (setq errput (with-temp-buffer
                           (insert-file-contents errfile)
                           (delete-file errfile)
                           (buffer-string))
                  errorp (not (equal 0 status))
                  no-chg (or errorp
                             (= 0 (compare-buffer-substrings inbuf nil nil
                                                             nil nil nil)))
                  output (unless no-chg
                           (buffer-string)))))
        (cond (errorp
               (message "Syntax error"))
              (no-chg
               (message "Already formatted"))
              (t
               (message "Reformatted!")
               (unibeautify-preserve-line-number
                (lambda ()
                  (erase-buffer)
                  (insert output)))))
        (with-current-buffer (get-buffer-create "*unibeautify-errors*")
          (erase-buffer)
          (unless (= 0 (length errput))
            (insert errput)
            (display-buffer (current-buffer))))))))

(provide 'unibeautify)

;;; unibeautify.el ends here
